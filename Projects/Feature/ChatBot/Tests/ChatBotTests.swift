import Foundation
import XCTest

import DomainInterface

import Dependencies

@testable import FeatureChatBot

@MainActor
final class ChatBotTests: XCTestCase {
    private nonisolated static func failingStream() -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            continuation.finish(throwing: URLError(.badServerResponse))
        }
    }

    private nonisolated static func historyStream(_ histories: ChatHistory...) -> AsyncThrowingStream<ChatHistory, Error> {
        AsyncThrowingStream { continuation in
            for history in histories {
                continuation.yield(history)
            }
            continuation.finish()
        }
    }

    private func waitUntil(timeout: Duration = .seconds(2), _ condition: () -> Bool) async {
        let deadline = ContinuousClock.now + timeout
        while !condition(), ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(20))
        }
    }

    func test_정지를_눌러도_로컬_Task는_취소되지_않고_서버_정지_요청만_보낸다() async {
        let box = StreamBox()
        let stopSpy = StopSpy()

        let viewModel = withDependencies {
            $0.chatRepository.streamMessage = { _, _ in box.openStream(yielding: "안녕") }
            $0.chatRepository.stopStreaming = { _ in stopSpy.record() }
        } operation: {
            ChatBotViewModel(context: .init(
                wordID: "word_001",
                term: "address",
                sentence: "I wrote my address.",
                levelLabel: "초급"
            ))
        }

        viewModel.input = "질문"
        viewModel.didTapSend()
        await waitUntil { !(viewModel.messages.last?.text.isEmpty ?? true) }

        viewModel.didTapStop()
        await waitUntil { stopSpy.callCount == 1 }

        XCTAssertTrue(viewModel.isStreaming)

        box.finish()
        await viewModel.streamTask?.value

        XCTAssertEqual(viewModel.messages.last?.text, "안녕")
        XCTAssertFalse(viewModel.isStreaming)
        XCTAssertEqual(viewModel.messages.last?.isError, false)

        viewModel.input = "다음 질문"
        XCTAssertTrue(viewModel.canSend)
    }

    func test_첫_응답_전에_정지해도_서버가_스트림을_닫아야_빈_자리표시_메시지가_제거된다() async {
        let box = StreamBox()

        let viewModel = withDependencies {
            $0.chatRepository.streamMessage = { _, _ in box.openStream() }
            $0.chatRepository.stopStreaming = { _ in box.finish() }
        } operation: {
            ChatBotViewModel(context: .init(
                wordID: "word_001",
                term: "address",
                sentence: "I wrote my address.",
                levelLabel: "초급"
            ))
        }

        viewModel.input = "질문"
        viewModel.didTapSend()
        viewModel.didTapStop()
        await viewModel.streamTask?.value

        XCTAssertEqual(viewModel.messages.count, 1)
        XCTAssertEqual(viewModel.messages.first?.role, .user)
        XCTAssertFalse(viewModel.messages.contains(where: { $0.isError }))
        XCTAssertFalse(viewModel.messages[0].isFromHistory)
    }

    func test_화면_이탈시_정지_요청과_함께_로컬_Task도_즉시_취소한다() async {
        let box = StreamBox()
        let stopSpy = StopSpy()

        let viewModel = withDependencies {
            $0.chatRepository.streamMessage = { _, _ in box.openStream(yielding: "안녕") }
            $0.chatRepository.stopStreaming = { _ in stopSpy.record() }
        } operation: {
            ChatBotViewModel(context: .init(
                wordID: "word_001",
                term: "address",
                sentence: "I wrote my address.",
                levelLabel: "초급"
            ))
        }

        viewModel.input = "질문"
        viewModel.didTapSend()
        await waitUntil { !(viewModel.messages.last?.text.isEmpty ?? true) }

        viewModel.onDisappear()
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
            ChatBotViewModel(context: .init(
                wordID: "word_001",
                term: "address",
                sentence: "I wrote my address.",
                levelLabel: "초급"
            ))
        }

        viewModel.input = "질문"
        viewModel.didTapSend()
        await viewModel.streamTask?.value

        XCTAssertEqual(viewModel.messages.last?.role, .assistant)
        XCTAssertEqual(viewModel.messages.last?.text, "답변을 가져오지 못했어요")
        XCTAssertEqual(viewModel.messages.last?.isError, true)

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
            ChatBotViewModel(context: .init(
                wordID: "word_001",
                term: "address",
                sentence: "I wrote my address.",
                levelLabel: "초급"
            ))
        }

        await viewModel.load()

        XCTAssertTrue(viewModel.isShowingLoginRequiredPopup)
    }

    func test_인증_상태면_onAppear_후_로그인_필요_팝업이_노출되지_않는다() async {
        let viewModel = withDependencies {
            $0.checkAuthSessionUseCase.execute = { true }
            $0.chatRepository.fetchHistory = { _ in Self.historyStream(ChatHistory(messages: [])) }
        } operation: {
            ChatBotViewModel(context: .init(
                wordID: "word_001",
                term: "address",
                sentence: "I wrote my address.",
                levelLabel: "초급"
            ))
        }

        await viewModel.load()

        XCTAssertFalse(viewModel.isShowingLoginRequiredPopup)
    }

    func test_나중에_탭하면_로그인_필요_팝업이_닫힌다() async {
        let viewModel = withDependencies {
            $0.checkAuthSessionUseCase.execute = { false }
        } operation: {
            ChatBotViewModel(context: .init(
                wordID: "word_001",
                term: "address",
                sentence: "I wrote my address.",
                levelLabel: "초급"
            ))
        }

        await viewModel.load()
        XCTAssertTrue(viewModel.isShowingLoginRequiredPopup)

        viewModel.didTapLater()

        XCTAssertFalse(viewModel.isShowingLoginRequiredPopup)
    }

    func test_인증_상태면_onAppear_시_서버가_준_순서_그대로_히스토리를_불러온다() async {
        let history = ChatHistory(messages: [
            .init(role: .user, content: "두번째 질문"),
            .init(role: .user, content: "첫 질문"),
            .init(role: .assistant, content: "첫 답변")
        ])

        let viewModel = withDependencies {
            $0.checkAuthSessionUseCase.execute = { true }
            $0.chatRepository.fetchHistory = { _ in Self.historyStream(history) }
        } operation: {
            ChatBotViewModel(context: .init(
                wordID: "word_001",
                term: "address",
                sentence: "I wrote my address.",
                levelLabel: "초급"
            ))
        }

        await viewModel.load()

        XCTAssertEqual(viewModel.messages.map(\.text), ["두번째 질문", "첫 질문", "첫 답변"])
        XCTAssertEqual(viewModel.messages.map(\.role), [.user, .user, .assistant])
        XCTAssertTrue(viewModel.messages.allSatisfy(\.isFromHistory))
    }

    func test_비인증_상태면_히스토리를_불러오지_않는다() async {
        let viewModel = withDependencies {
            $0.checkAuthSessionUseCase.execute = { false }
        } operation: {
            ChatBotViewModel(context: .init(
                wordID: "word_001",
                term: "address",
                sentence: "I wrote my address.",
                levelLabel: "초급"
            ))
        }

        await viewModel.load()

        XCTAssertTrue(viewModel.messages.isEmpty)
    }

    func test_두번째_onAppear에서는_히스토리를_다시_불러오지_않는다() async {
        let history = ChatHistory(messages: [.init(role: .user, content: "질문")])
        let counter = CallCounter()

        let viewModel = withDependencies {
            $0.checkAuthSessionUseCase.execute = { true }
            $0.chatRepository.fetchHistory = { _ in
                counter.increment()
                return Self.historyStream(history)
            }
        } operation: {
            ChatBotViewModel(context: .init(
                wordID: "word_001",
                term: "address",
                sentence: "I wrote my address.",
                levelLabel: "초급"
            ))
        }

        await viewModel.load()
        await viewModel.load()

        XCTAssertEqual(counter.value, 1)
    }

    func test_로컬_스냅샷_이후_서버_스냅샷이_오면_히스토리_메시지가_중복_없이_교체된다() async {
        let localHistory = ChatHistory(messages: [.init(role: .user, content: "로컬 질문")])
        let remoteHistory = ChatHistory(messages: [
            .init(role: .user, content: "로컬 질문"),
            .init(role: .assistant, content: "서버 답변")
        ])

        let viewModel = withDependencies {
            $0.checkAuthSessionUseCase.execute = { true }
            $0.chatRepository.fetchHistory = { _ in Self.historyStream(localHistory, remoteHistory) }
        } operation: {
            ChatBotViewModel(context: .init(
                wordID: "word_001",
                term: "address",
                sentence: "I wrote my address.",
                levelLabel: "초급"
            ))
        }

        await viewModel.load()

        XCTAssertEqual(viewModel.messages.map(\.text), ["로컬 질문", "서버 답변"])
        XCTAssertTrue(viewModel.messages.allSatisfy(\.isFromHistory))
    }
}

private final class CallCounter: @unchecked Sendable {
    private(set) var value = 0
    func increment() { value += 1 }
}

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

private final class StopSpy: @unchecked Sendable {
    private(set) var callCount = 0
    func record() { callCount += 1 }
}
