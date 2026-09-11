import Foundation
import XCTest

import DomainInterface

import Dependencies

@testable import FeatureChatBot

@MainActor
final class ChatBotTests: XCTestCase {
    // chatRepository.streamMessage는 nonisolated @Sendable 클로저라, 이 클래스의
    // @MainActor 격리를 타지 않는 static 헬퍼로 스트림을 만든다.

    /// 청크를 하나 yield한 뒤 `finish`하지 않고 열어 둔 스트림 — 취소될 때까지 끝나지 않는다.
    private nonisolated static func openStream(yielding chunk: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(chunk)
        }
    }

    /// 아무것도 yield하지 않고 열어 둔 스트림 — 첫 응답 전 취소 시나리오용.
    private nonisolated static func neverYieldingStream() -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { _ in }
    }

    /// 즉시 에러로 끝나는 스트림 — 취소가 아닌 진짜 실패 시나리오용.
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
    /// 직접 대기해야 할 때 쓴다.
    private func waitUntil(timeout: Duration = .seconds(2), _ condition: () -> Bool) async {
        let deadline = ContinuousClock.now + timeout
        while !condition(), ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(20))
        }
    }

    func test_스트리밍_중_취소하면_누적된_텍스트를_보존하고_스트리밍_상태를_복구한다() async {
        let viewModel = withDependencies {
            $0.chatRepository.streamMessage = { _, _ in Self.openStream(yielding: "안녕") }
        } operation: {
            ChatBotViewModel(context: .init(wordID: "word_001", term: "address", sentence: "I wrote my address.", levelLabel: "초급"))
        }

        viewModel.input = "질문"
        viewModel.didTapSend()

        await waitUntil { !(viewModel.messages.last?.text.isEmpty ?? true) }

        viewModel.didTapCancel()
        await viewModel.streamTask?.value

        XCTAssertEqual(viewModel.messages.last?.text, "안녕")
        XCTAssertFalse(viewModel.isStreaming)
        XCTAssertEqual(viewModel.messages.last?.isError, false)

        // 버튼이 취소 상태로 굳지 않고 다시 전송 가능한 상태로 복구됐는지 함께 확인한다.
        viewModel.input = "다음 질문"
        XCTAssertTrue(viewModel.canSend)
    }

    func test_첫_응답_전에_취소하면_빈_자리표시_메시지를_제거한다() async {
        let viewModel = withDependencies {
            $0.chatRepository.streamMessage = { _, _ in Self.neverYieldingStream() }
        } operation: {
            ChatBotViewModel(context: .init(wordID: "word_001", term: "address", sentence: "I wrote my address.", levelLabel: "초급"))
        }

        viewModel.input = "질문"
        viewModel.didTapSend()
        viewModel.didTapCancel()
        await viewModel.streamTask?.value

        XCTAssertEqual(viewModel.messages.count, 1)
        XCTAssertEqual(viewModel.messages.first?.role, .user)
        XCTAssertFalse(viewModel.messages.contains(where: { $0.isError }))
        // 이번 세션에서 직접 보낸 메시지는 히스토리 출신이 아니다.
        XCTAssertFalse(viewModel.messages[0].isFromHistory)
    }

    func test_실패하면_AI_메시지로_표시되고_다음_전송_시_히스토리에서_사라진다() async {
        let viewModel = withDependencies {
            $0.chatRepository.streamMessage = { _, _ in Self.failingStream() }
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
            $0.chatRepository.streamMessage = { _, _ in Self.neverYieldingStream() }
        } operation: {
            viewModel.input = "다음 질문"
            viewModel.didTapSend()
        }

        XCTAssertFalse(viewModel.messages.contains(where: { $0.isError }))

        viewModel.didTapCancel()
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
