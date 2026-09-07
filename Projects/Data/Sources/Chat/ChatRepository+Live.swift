import Foundation

import DomainInterface

import Dependencies

extension ChatRepository: DependencyKey {
    public static let liveValue = ChatRepository(
        streamMessage: { message in
            AsyncThrowingStream { continuation in
                let task = Task {
                    @Dependency(\.chatBotRemoteDataSource) var remoteDataSource
                    do {
                        for try await event in remoteDataSource.streamEvents(message: message) {
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
