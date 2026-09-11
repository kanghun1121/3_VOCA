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
                    @Dependency(\.chatSessionStore) var sessionStore

                    // sse_id 발급/진행 중 표시, conversation_id 조회/갱신은 전부 세션 스토어
                    // 안에서 끝난다 — ChatRepository의 공개 포트에도, ViewModel에도 안 새어나간다
                    // (서브플랜 10 정정: 처음엔 이 값들을 포트 파라미터로 노출했다가, "정지
                    // 프로토콜이 바뀌면 ViewModel도 바뀌게 된다"는 지적을 받아 전부 Data 레이어
                    // 내부(ChatSessionStore)로 옮겼다).
                    let sseID = await sessionStore.beginSend(wordID: wordID)
                    let conversationID = await sessionStore.conversationID(for: wordID)

                    var fullText = ""
                    var streamError: Error?
                    do {
                        let events = await chatDataSource.streamEvents(
                            message: message,
                            wordID: wordID,
                            sseID: sseID,
                            conversationID: conversationID,
                            onConversationID: { newConversationID in
                                Task { await sessionStore.setConversationID(newConversationID, wordID: wordID) }
                            }
                        )
                        for try await event in events {
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

                    await sessionStore.endSend(wordID: wordID)

                    // ViewModel의 "취소는 실패가 아니다" 판단과 동일한 기준(Task.isCancelled)을
                    // 재사용해, 정상 종료거나 취소 중 부분 텍스트가 남은 경우에만 로컬 캐시에
                    // 반영한다. 진짜 네트워크 실패는 부분 텍스트를 버린다(화면에서도 실패 문구로
                    // 대체되는 것과 동일한 기준) — 캐싱 여부 판단은 순수하게 이 Data 레이어 안에서
                    // 끝나고 ViewModel은 이 부수효과를 전혀 모른다(서브플랜 9 결정 6). 서브플랜
                    // 10부터 "정지"는 로컬 Task를 취소하지 않고 서버가 스스로 스트림을 닫게
                    // 하므로(streamError == nil), 정지된 전송도 대부분 이 조건의 첫 갈래로
                    // 캐시된다 — Task.isCancelled 갈래는 이제 화면 이탈(onDisappear)처럼 로컬을
                    // 실제로 취소하는 경로에서만 의미가 있다.
                    if !fullText.isEmpty, streamError == nil || Task.isCancelled {
                        let existing = (try? await localDataSource.messages(wordID: wordID)) ?? []
                        let newPayloads = [
                            ChatMessagePayload(
                                id: 0,
                                role: "user",
                                content: message
                            ),
                            ChatMessagePayload(
                                id: 0,
                                role: "assistant",
                                content: fullText
                            ),
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
        },
        stopStreaming: { wordID in
            @Dependency(\.chatSessionStore) var sessionStore
            @Dependency(\.chatBotRemoteDataSource) var chatDataSource
            guard let sseID = await sessionStore.activeSSEID(for: wordID) else { return }
            try await chatDataSource.stop(sseID: sseID)
        }
    )
}
