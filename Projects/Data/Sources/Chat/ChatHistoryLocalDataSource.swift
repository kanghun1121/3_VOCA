import Foundation
import SwiftData

import Dependencies

struct ChatHistoryLocalDataSource: Sendable {
    @Dependency(\.localDatabaseContext) private var context

    func messages(wordID: String) async throws -> [ChatMessagePayload] {
        try await context.fetch(FetchDescriptor<ChatHistoryEntity>(
            predicate: #Predicate { $0.wordID == wordID }
        )).first?.messages ?? []
    }

    /// 해당 wordID의 행이 있으면 메시지 배열을 통째로 교체하고, 없으면 새로 만든다. fetch→분기→save를
    /// 하나의 액터 격리 안에서 수행해 원자성을 보장한다(`LearningHistoryLocalDataSource.recordCompletion`과
    /// 동일한 패턴).
    func save(wordID: String, messages: [ChatMessagePayload]) async throws {
        try await context.withContext { modelContext in
            let existing = try modelContext.fetch(FetchDescriptor<ChatHistoryEntity>(
                predicate: #Predicate { $0.wordID == wordID }
            )).first
            if let existing {
                existing.messages = messages
            } else {
                modelContext.insert(ChatHistoryEntity(wordID: wordID, messages: messages))
            }
            try modelContext.save()
        }
    }
}

extension ChatHistoryLocalDataSource: DependencyKey {
    static let liveValue = ChatHistoryLocalDataSource()
}

extension ChatHistoryLocalDataSource: TestDependencyKey {
    static let testValue = ChatHistoryLocalDataSource()
}

extension DependencyValues {
    var chatHistoryLocalDataSource: ChatHistoryLocalDataSource {
        get { self[ChatHistoryLocalDataSource.self] }
        set { self[ChatHistoryLocalDataSource.self] = newValue }
    }
}
