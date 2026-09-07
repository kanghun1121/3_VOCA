import Foundation

import DomainInterface

import Dependencies

extension ChatRepository: DependencyKey {
    public static let liveValue = ChatRepository(
        streamMessage: { message in
            AsyncThrowingStream { continuation in
                let task = Task {
                    @Dependency(\.chatBotRemoteDataSource) var remote
                    do {
                        for try await event in remote.streamEvents(message: message) {
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
}
