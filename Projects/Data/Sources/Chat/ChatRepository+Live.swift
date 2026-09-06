import Foundation

import DomainInterface
import NetworkingInterface

import Dependencies

extension ChatRepository: DependencyKey {
    private static let model = "claude-sonnet-5"
    private static let maxTokens = 2048

    public static let liveValue: ChatRepository = {
        @Dependency(\.sseClient) var sseClient
        return ChatRepository(
            streamMessage: { message in
                AsyncThrowingStream { continuation in
                    let task = Task {
                        let request = ChatProxyRequest(
                            model: Self.model,
                            maxTokens: Self.maxTokens,
                            messages: [ChatProxyMessage(role: "user", content: message)]
                        )
                        let frames = sseClient.stream(request)
                        do {
                            for try await event in ChatProxySSEParser.parse(frames: frames) {
                                if case let .textDelta(text) = event {
                                    continuation.yield(text)
                                }
                            }
                            continuation.finish()
                        } catch {
                            continuation.finish(throwing: error)
                        }
                    }
                    continuation.onTermination = { _ in task.cancel() }
                }
            }
        )
    }()
}
