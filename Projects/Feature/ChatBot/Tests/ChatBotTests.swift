import Foundation
import XCTest

import DomainInterface

import Dependencies

@testable import FeatureChatBot

@MainActor
final class ChatBotTests: XCTestCase {
    // chatRepository.streamMessage는 nonisolated @Sendable 클로저라, 이 클래스의
    // @MainActor 격리를 타지 않는 static 헬퍼로 스트림을 만든다.

    /// 즉시 에러로 끝나는 스트림 — 정지가 아닌 진짜 실패 시나리오용.
    private nonisolated static func failingStream() -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            continuation.finish(throwing: URLError(.badServerResponse))
        }
    }

    /// `fetchHistory`가 인자로 준 순서대로 emit한 뒤 finish하는 스트림 — 로컬→서버 2단계
    /// emit을 흉내낸다(인자 1개면 기존처럼 단발 emit).
    private nonisolated static func historyStream(_ histories: ChatHistory...) -> AsyncThrowingStream<ChatHistory, Error> {
        AsyncThrowingStream { continuation in
            for history in histories {
                continuation.yield(history)
            }
            continuation.finish()
        }
    }

    /// 즉시 에러로 끝나는 히스토리 스트림 — 서버 조회 실패 시나리오용.
    private nonisolated static func failingHistoryStream() -> AsyncThrowingStream<ChatHistory, Error> {
        AsyncThrowingStream { continuation in
            continuation.finish(throwing: URLError(.badServerResponse))
        }
    }

    /// 조건이 참이 될 때까지 짧게 폴링한다. 타이핑 연출이 비동기라 텍스트가 반영되는 시점을
    /// 직접 대기해야 하거나, 정지 요청처럼 별도 unstructured Task로 실행되는 부수효과의 완료를
    /// 기다려야 할 때 쓴다.
    private func waitUntil(timeout: Duration = .seconds(2), _ condition: () -> Bool) async {
        let deadline = ContinuousClock.now + timeout
        while !condition(), ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(20))
        }
    }

    func test_정지를_눌러도_로컬_Task는_취소되지_않고_서버_정지_요청만_보낸다() async {
        // 서브플랜 10: 정지는 로컬에서 스트림을 강제로 끊지 않는다. 서버가 지금까지 생성한
        // 내용을 마저 흘려보낸 뒤 스스로 스트림을 닫을 때까지(여기서는 box.finish()로 흉내냄)
        // 계속 소비하며 화면에도 반영된다.
        let box = StreamBox()
        let stopSpy = StopSpy()

        let viewModel = withDependencies {
            $0.chatRepository.streamMessage = { _, _ in box.openStream(yielding: "안녕") }
            $0.chatRepository.stopStreaming = { _ in stopSpy.record() }
        } operation: {
            ChatBotViewModel(context: .init(wordID: "word_001", term: "address", sentence: "I wrote my address.", levelLabel: "초급"))
        }

        viewModel.input = "질문"
        viewModel.didTapSend()
        await waitUntil { !(viewModel.messages.last?.text.isEmpty ?? true) }

        viewModel.didTapStop()
        await waitUntil { stopSpy.callCount == 1 }

        // 정지 요청은 보냈지만 서버가 아직 스트림을 안 닫았으므로 계속 스트리밍 중이어야 한다.
        XCTAssertTrue(viewModel.isStreaming)

        // 서버가 스스로 스트림을 닫으면(box.finish) 그제서야 정상 종료된다.
        box.finish()
        await viewModel.streamTask?.value

        XCTAssertEqual(viewModel.messages.last?.text, "안녕")
        XCTAssertFalse(viewModel.isStreaming)
        XCTAssertEqual(viewModel.messages.last?.isError, false)

        // 버튼이 정지 상태로 굳지 않고 다시 전송 가능한 상태로 복구됐는지 함께 확인한다.
        viewModel.input = "다음 질문"
        XCTAssertTrue(viewModel.canSend)
    }

    func test_첫_응답_전에_정지해도_서버가_스트림을_닫아야_빈_자리표시_메시지가_제거된다() async {
        let box = StreamBox()

        let viewModel = withDependencies {
            $0.chatRepository.streamMessage = { _, _ in box.openStream() }
            $0.chatRepository.stopStreaming = { _ in box.finish() }
        } operation: {
            ChatBotViewModel(context: .init(wordID: "word_001", term: "address", sentence: "I wrote my address.", levelLabel: "초급"))
        }

        viewModel.input = "질문"
        viewModel.didTapSend()
        viewModel.didTapStop()
        await viewModel.streamTask?.value

        XCTAssertEqual(viewModel.messages.count, 1)
        XCTAssertEqual(viewModel.messages.first?.role, .user)
        XCTAssertFalse(viewModel.messages.contains(where: { $0.isError }))
        // 이번 세션에서 직접 보낸 메시지는 히스토리 출신이 아니다.
        XCTAssertFalse(viewModel.messages[0].isFromHistory)
    }

    func test_화면_이탈시_정지_요청과_함께_로컬_Task도_즉시_취소한다() async {
        // onDisappear는 정지 버튼과 달리 서버가 스트림을 닫을 때까지 기다리지 않는다 — 화면이
        // 사라졌으니 더 보여줄 이유가 없어 로컬 Task를 즉시 취소한다. 다만 서버 쪽 생성도 계속
        // 이어갈 이유가 없어 stop 요청은 함께 보낸다.
        let box = StreamBox()
        let stopSpy = StopSpy()

        let viewModel = withDependencies {
            $0.chatRepository.streamMessage = { _, _ in box.openStream(yielding: "안녕") }
            $0.chatRepository.stopStreaming = { _ in stopSpy.record() }
        } operation: {
            ChatBotViewModel(context: .init(wordID: "word_001", term: "address", sentence: "I wrote my address.", levelLabel: "초급"))
        }

        viewModel.input = "질문"
        viewModel.didTapSend()
        await waitUntil { !(viewModel.messages.last?.text.isEmpty ?? true) }

        viewModel.onDisappear()
        // box는 finish되지 않지만(서버 응답을 기다리지 않음) 로컬 취소만으로 스트림이 끝난다.
        await viewModel.streamTask?.value

        await waitUntil { stopSpy.callCount == 1 }
        XCTAssertEqual(stopSpy.callCount, 1)
        XCTAssertFalse(viewModel.isStreaming)
    }

    func test_실패하면_AI_메시지로_표시되고_다음_전송_시_히스토리에서_사라진다() async {
        let secondBox = StreamBox()

        let viewModel = withDependencies {
            $0.chatRepository.streamMessage = { _, _ in Self.failingStream() }
            $0.chatRepository.stopStreaming = { _ in secondBox.finish() }
        } operation: {
            ChatBotViewModel(context: .init(wordID: "word_001", term: "address", sentence: "I wrote my address.", levelLabel: "초급"))
        }

        viewModel.input = "질문"
        viewModel.didTapSend()
        await viewModel.streamTask?.value

        XCTAssertEqual(viewModel.messages.last?.role, .assistant)
        XCTAssertEqual(viewModel.messages.last?.text, "답변을 가져오지 못했어요")
        XCTAssertEqual(viewModel.messages.last?.isError, true)

        // 다음 전송을 시작하는 순간 실패 메시지는 히스토리에서 사라진다.
        withDependencies {
            $0.chatRepository.streamMessage = { _, _ in secondBox.openStream() }
        } operation: {
            viewModel.input = "다음 질문"
            viewModel.didTapSend()
        }

        XCTAssertFalse(viewModel.messages.contains(where: { $0.isError }))

        viewModel.didTapStop()
        await viewModel.streamTask?.value
    }

    func test_미인증_상태면_onAppear_후_로그인_필요_팝업이_노출된다() async {
        let viewModel = withDependencies {
            $0.checkAuthSessionUseCase.execute = { false }
        } operation: {
            ChatBotViewModel(context: .init(wordID: "word_001", term: "address", sentence: "I wrote my address.", levelLabel: "초급"))
        }

        await viewModel.onAppear()

        XCTAssertTrue(viewModel.isShowingLoginRequiredPopup)
    }

    func test_인증_상태면_onAppear_후_로그인_필요_팝업이_노출되지_않는다() async {
        let viewModel = withDependencies {
            $0.checkAuthSessionUseCase.execute = { true }
            $0.chatRepository.fetchHistory = { _ in Self.historyStream(ChatHistory(messages: [])) }
        } operation: {
            ChatBotViewModel(context: .init(wordID: "word_001", term: "address", sentence: "I wrote my address.", levelLabel: "초급"))
        }

        await viewModel.onAppear()

        XCTAssertFalse(viewModel.isShowingLoginRequiredPopup)
    }

    func test_나중에_탭하면_로그인_필요_팝업이_닫힌다() async {
        let viewModel = withDependencies {
            $0.checkAuthSessionUseCase.execute = { false }
        } operation: {
            ChatBotViewModel(context: .init(wordID: "word_001", term: "address", sentence: "I wrote my address.", levelLabel: "초급"))
        }

        await viewModel.onAppear()
        XCTAssertTrue(viewModel.isShowingLoginRequiredPopup)

        viewModel.didTapLater()

        XCTAssertFalse(viewModel.isShowingLoginRequiredPopup)
    }

    // MARK: - 대화 히스토리 로드

    func test_인증_상태면_onAppear_시_서버가_준_순서_그대로_히스토리를_불러온다() async {
        // 여러 conversation을 하나로 평탄화하는 작업은 매핑 계층(ChatHistoryResponseDTO+Mapping)
        // 책임으로 옮겨졌다 — ChatHistory.messages는 이미 평탄화된 단일 목록으로 들어오므로,
        // 여기서는 ViewModel이 그 순서를 그대로 믿고 매핑하는지만 검증한다.
        let history = ChatHistory(messages: [
            .init(id: 3, role: .user, content: "두번째 질문"),
            .init(id: 1, role: .user, content: "첫 질문"),
            .init(id: 2, role: .assistant, content: "첫 답변")
        ])

        let viewModel = withDependencies {
            $0.checkAuthSessionUseCase.execute = { true }
            $0.chatRepository.fetchHistory = { _ in Self.historyStream(history) }
        } operation: {
            ChatBotViewModel(context: .init(wordID: "word_001", term: "address", sentence: "I wrote my address.", levelLabel: "초급"))
        }

        await viewModel.onAppear()

        XCTAssertEqual(viewModel.messages.map(\.text), ["두번째 질문", "첫 질문", "첫 답변"])
        XCTAssertEqual(viewModel.messages.map(\.role), [.user, .user, .assistant])
        // 히스토리로 불러온 메시지는 isFromHistory가 true여야 한다 — ChatBotContentView가
        // 이 값으로 "방금 보낸 메시지"와 구분해 전송 전용 레이아웃 연출을 걸러낸다.
        XCTAssertTrue(viewModel.messages.allSatisfy(\.isFromHistory))
    }

    func test_비인증_상태면_히스토리를_불러오지_않는다() async {
        let viewModel = withDependencies {
            $0.checkAuthSessionUseCase.execute = { false }
            // fetchHistory는 unimplemented(testValue 기본값)로 남겨둔다 — 호출되면 테스트가 실패한다.
        } operation: {
            ChatBotViewModel(context: .init(wordID: "word_001", term: "address", sentence: "I wrote my address.", levelLabel: "초급"))
        }

        await viewModel.onAppear()

        XCTAssertTrue(viewModel.messages.isEmpty)
    }

    func test_두번째_onAppear에서는_히스토리를_다시_불러오지_않는다() async {
        let history = ChatHistory(messages: [.init(id: 1, role: .user, content: "질문")])
        let counter = CallCounter()

        let viewModel = withDependencies {
            $0.checkAuthSessionUseCase.execute = { true }
            $0.chatRepository.fetchHistory = { _ in
                counter.increment()
                return Self.historyStream(history)
            }
        } operation: {
            ChatBotViewModel(context: .init(wordID: "word_001", term: "address", sentence: "I wrote my address.", levelLabel: "초급"))
        }

        await viewModel.onAppear()
        await viewModel.onAppear()

        XCTAssertEqual(counter.value, 1)
    }

    func test_히스토리_로드_실패시_isHistoryLoadFailed가_true가_되고_재시도하면_복구된다() async {
        let history = ChatHistory(messages: [.init(id: 1, role: .user, content: "질문")])

        let viewModel = withDependencies {
            $0.checkAuthSessionUseCase.execute = { true }
            $0.chatRepository.fetchHistory = { _ in Self.failingHistoryStream() }
        } operation: {
            ChatBotViewModel(context: .init(wordID: "word_001", term: "address", sentence: "I wrote my address.", levelLabel: "초급"))
        }

        await viewModel.onAppear()

        XCTAssertTrue(viewModel.isHistoryLoadFailed)
        XCTAssertFalse(viewModel.hasLoadedHistory)

        withDependencies {
            $0.chatRepository.fetchHistory = { _ in Self.historyStream(history) }
        } operation: {
            viewModel.didTapRetryHistoryLoad()
        }
        await Task.yield()
        await waitUntil { viewModel.hasLoadedHistory }

        XCTAssertFalse(viewModel.isHistoryLoadFailed)
        XCTAssertEqual(viewModel.messages.map(\.text), ["질문"])
    }

    func test_로컬_스냅샷_이후_서버_스냅샷이_오면_히스토리_메시지가_중복_없이_교체된다() async {
        // fetchHistory는 로컬→서버 순으로 최대 2번 emit할 수 있다(서브플랜 9). 두 번째
        // emit이 첫 번째 emit 위에 또 추가되는 게 아니라, 히스토리 태그된 메시지를 지우고
        // 새로 교체하는지 검증한다.
        let localHistory = ChatHistory(messages: [.init(id: 1, role: .user, content: "로컬 질문")])
        let remoteHistory = ChatHistory(messages: [
            .init(id: 1, role: .user, content: "로컬 질문"),
            .init(id: 2, role: .assistant, content: "서버 답변")
        ])

        let viewModel = withDependencies {
            $0.checkAuthSessionUseCase.execute = { true }
            $0.chatRepository.fetchHistory = { _ in Self.historyStream(localHistory, remoteHistory) }
        } operation: {
            ChatBotViewModel(context: .init(wordID: "word_001", term: "address", sentence: "I wrote my address.", levelLabel: "초급"))
        }

        await viewModel.onAppear()

        XCTAssertEqual(viewModel.messages.map(\.text), ["로컬 질문", "서버 답변"])
        XCTAssertTrue(viewModel.messages.allSatisfy(\.isFromHistory))
        XCTAssertTrue(viewModel.hasLoadedHistory)
    }
}

/// 테스트 전용 — `fetchHistory`가 몇 번 호출됐는지 세기 위한 카운터.
private final class CallCounter: @unchecked Sendable {
    private(set) var value = 0
    func increment() { value += 1 }
}

/// `streamMessage`가 반환할 `AsyncThrowingStream`의 continuation을 테스트 쪽에서 들고 있다가,
/// "서버가 정지 요청을 받고 스스로 스트림을 닫는다"를 `finish()` 호출로 흉내낸다(서브플랜 10) —
/// 정지가 더 이상 로컬 Task를 취소하지 않으므로, 스트림을 끝내는 유일한 방법은 이제 이것뿐이다.
/// `chunk`가 nil이면 아무것도 yield하지 않은 채로 열어 둔다(첫 응답 전 정지 시나리오용).
private final class StreamBox: @unchecked Sendable {
    private var continuation: AsyncThrowingStream<String, Error>.Continuation?

    func openStream(yielding chunk: String? = nil) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            self.continuation = continuation
            if let chunk {
                continuation.yield(chunk)
            }
        }
    }

    func finish() {
        continuation?.finish()
    }
}

/// `stopStreaming` 호출 횟수를 기록하는 스파이. `SpyHTTPInterceptor`(Networking 모듈)와 동일한
/// 패턴 — 비MainActor Task에서 호출되므로 `@unchecked Sendable` 클래스로 안전하게 캡처한다.
private final class StopSpy: @unchecked Sendable {
    private(set) var callCount = 0
    func record() { callCount += 1 }
}
