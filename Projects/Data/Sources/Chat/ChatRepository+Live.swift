import Foundation

import DomainInterface

import Dependencies

extension ChatRepository: DependencyKey {
    public static let liveValue = ChatRepository(
        streamMessage: { message, wordID in
            AsyncThrowingStream { continuation in
                let task = Task {
                    @Dependency(\.chatBotRemoteDataSource) var chatDataSource
                    @Dependency(\.chatHistoryLocalDataSource) var localDataSource

                    var fullText = ""
                    var streamError: Error?
                    do {
                        for try await event in chatDataSource.streamEvents(message: message) {
                            if case let .textDelta(text) = event {
                                fullText += text
                                continuation.yield(text)
                            }
                        }
                        continuation.finish()
                    } catch {
                        streamError = error
                        continuation.finish(throwing: error)
                    }

                    // 취소는 실패가 아니다 — 정상 종료거나, 취소됐지만 부분 텍스트가 남은
                    // 경우에만 로컬 캐시에 반영한다. 진짜 네트워크 실패는 부분 텍스트를
                    // 버린다(화면에서도 실패 문구로 대체되는 것과 동일한 기준).
                    if !fullText.isEmpty, streamError == nil || Task.isCancelled {
                        let existing = (try? await localDataSource.messages(wordID: wordID)) ?? []
                        let newPayloads = [
                            ChatMessagePayload(id: 0, role: "user", content: message),
                            ChatMessagePayload(id: 0, role: "assistant", content: fullText),
                        ]
                        try? await localDataSource.save(wordID: wordID, messages: existing + newPayloads)
                    }
                }
                continuation.onTermination = { _ in task.cancel() }
            }
        },
        fetchHistory: { wordID in
            AsyncThrowingStream { continuation in
                let task = Task {
                    @Dependency(\.chatHistoryLocalDataSource) var localDataSource
                    @Dependency(\.chatBotRemoteDataSource) var remoteDataSource

                    // 1. 로컬 먼저 — 읽기/역할 파싱 실패해도(첫 실행 등) 전체를 막지 않고 조용히 건너뛴다.
                    do {
                        let cachedPayloads = try await localDataSource.messages(wordID: wordID)
                        let cachedMessages = try cachedPayloads.map { try $0.toDomain() }
                        continuation.yield(ChatHistory(messages: cachedMessages))
                    } catch {
                        // 캐시 없음/파싱 실패는 "보여줄 로컬 데이터가 없다"와 동일하게 취급 — 무시하고 계속 진행.
                    }

                    // 2. 서버 — 실패하면 스트림 전체를 에러로 종료(기존 catch-all과 동일한 수준의 실패 처리).
                    do {
                        let dto = try await remoteDataSource.fetchHistory(wordID: wordID)
                        let remoteHistory = try dto.toDomain()
                        try await localDataSource.save(wordID: wordID, messages: remoteHistory.messages.map(\.asPayload))
                        continuation.yield(remoteHistory)
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
