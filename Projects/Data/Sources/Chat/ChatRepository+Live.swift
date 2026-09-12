import Foundation

import DomainInterface

import Dependencies

extension ChatRepository: DependencyKey {
    public static let liveValue: ChatRepository = {
        @Dependency(\.chatBotRemoteDataSource) var chatDataSource
        @Dependency(\.chatHistoryLocalDataSource) var localDataSource
        @Dependency(\.chatSessionStore) var sessionStore

        return ChatRepository(
            streamMessage: { message, wordID in
                AsyncThrowingStream { continuation in
                    let task = Task {
                        let sseID = await sessionStore.beginSend(wordID: wordID)
                        let conversationID = await sessionStore.conversationID(for: wordID)

                        var fullText = ""

                        do {
                            let events = await chatDataSource.streamEvents(
                                message: message,
                                wordID: wordID,
                                sseID: sseID,
                                conversationID: conversationID
                            ) { newConversationID in
                                Task { await sessionStore.setConversationID(newConversationID, wordID: wordID) }
                            }

                            for try await event in events {
                                if case let .textDelta(text) = event {
                                    fullText += text
                                    continuation.yield(text)
                                }
                            }

                            continuation.finish()
                            await sessionStore.endSend(wordID: wordID)

                            if !fullText.isEmpty {
                                let existing = (try? await localDataSource.messages(wordID: wordID)) ?? []
                                let newPayloads = [
                                    ChatMessagePayload(role: "user", content: message),
                                    ChatMessagePayload(role: "assistant", content: fullText),
                                ]
                                try? await localDataSource.save(wordID: wordID, messages: existing + newPayloads)
                            }
                        } catch {
                            continuation.finish(throwing: error)
                            await sessionStore.endSend(wordID: wordID)
                        }
                    }
                    continuation.onTermination = { _ in task.cancel() }
                }
            },
            fetchHistory: { wordID in
                AsyncThrowingStream { continuation in
                    let task = Task {
                        if let cachedMessages = try? await localDataSource.messages(wordID: wordID).map { try $0.toDomain() } {
                            continuation.yield(ChatHistory(messages: cachedMessages))
                        }

                        if let remoteHistory = try? await chatDataSource.fetchHistory(wordID: wordID).toDomain() {
                            try? await localDataSource.save(wordID: wordID, messages: remoteHistory.messages.map(\.asPayload))
                            continuation.yield(remoteHistory)
                        }

                        continuation.finish()
                    }
                    continuation.onTermination = { _ in task.cancel() }
                }
            },
            stopStreaming: { wordID in
                guard let sseID = await sessionStore.activeSSEID(for: wordID) else { return }
                try await chatDataSource.stop(sseID: sseID)
            }
        )
    }()
}
