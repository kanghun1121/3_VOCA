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

    /// 조건이 참이 될 때까지 짧게 폴링한다. 타이핑 연출(80ms 간격)이 비동기라
    /// 텍스트가 반영되는 시점을 직접 대기해야 하는 1번 케이스에서만 쓴다.
    private func waitUntil(timeout: Duration = .seconds(2), _ condition: () -> Bool) async {
        let deadline = ContinuousClock.now + timeout
        while !condition(), ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(20))
        }
    }

    func test_스트리밍_중_취소하면_누적된_텍스트를_보존하고_스트리밍_상태를_복구한다() async {
        let viewModel = withDependencies {
            $0.chatRepository.streamMessage = { _ in Self.openStream(yielding: "안녕") }
        } operation: {
            ChatBotViewModel(context: .init(term: "address", sentence: "I wrote my address.", levelLabel: "초급"))
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
            $0.chatRepository.streamMessage = { _ in Self.neverYieldingStream() }
        } operation: {
            ChatBotViewModel(context: .init(term: "address", sentence: "I wrote my address.", levelLabel: "초급"))
        }

        viewModel.input = "질문"
        viewModel.didTapSend()
        viewModel.didTapCancel()
        await viewModel.streamTask?.value

        XCTAssertEqual(viewModel.messages.count, 1)
        XCTAssertEqual(viewModel.messages.first?.role, .user)
        XCTAssertFalse(viewModel.messages.contains(where: { $0.isError }))
    }

    func test_실패하면_AI_메시지로_표시되고_다음_전송_시_히스토리에서_사라진다() async {
        let viewModel = withDependencies {
            $0.chatRepository.streamMessage = { _ in Self.failingStream() }
        } operation: {
            ChatBotViewModel(context: .init(term: "address", sentence: "I wrote my address.", levelLabel: "초급"))
        }

        viewModel.input = "질문"
        viewModel.didTapSend()
        await viewModel.streamTask?.value

        XCTAssertEqual(viewModel.messages.last?.role, .assistant)
        XCTAssertEqual(viewModel.messages.last?.text, "답변을 가져오지 못했어요")
        XCTAssertEqual(viewModel.messages.last?.isError, true)

        // 다음 전송을 시작하는 순간 실패 메시지는 히스토리에서 사라진다.
        withDependencies {
            $0.chatRepository.streamMessage = { _ in Self.neverYieldingStream() }
        } operation: {
            viewModel.input = "다음 질문"
            viewModel.didTapSend()
        }

        XCTAssertFalse(viewModel.messages.contains(where: { $0.isError }))

        viewModel.didTapCancel()
        await viewModel.streamTask?.value
    }
}
