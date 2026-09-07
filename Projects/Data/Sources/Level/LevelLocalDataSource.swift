import Foundation
import SwiftData

import Dependencies

/// `LevelEntity`만 소유한다. Lesson(레슨 상세의 cefrLabel 조회)과 VocabularyLibrary(레벨
/// 목록 스켈레톤) 양쪽에서 재사용되어 별도 도메인으로 독립시켰다.
struct LevelLocalDataSource: Sendable {
    @Dependency(\.localDatabaseContext) private var context

    func level(id: Int) async throws -> LevelEntity? {
        try await context.fetch(FetchDescriptor<LevelEntity>(
            predicate: #Predicate { $0.id == id }
        )).first
    }

    /// sortOrder 오름차순 — VocabularyLibrary 화면에 노출되는 레벨 순서다.
    func allLevels() async throws -> [LevelEntity] {
        try await context.fetch(FetchDescriptor<LevelEntity>(
            sortBy: [SortDescriptor(\.sortOrder)]
        ))
    }

    func insertLevels(_ levels: [LevelEntity]) async {
        for level in levels {
            await context.insert(level)
        }
    }
}

extension LevelLocalDataSource: DependencyKey {
    static let liveValue = LevelLocalDataSource()
}

extension LevelLocalDataSource: TestDependencyKey {
    static let testValue = LevelLocalDataSource()
}

extension DependencyValues {
    var levelLocalDataSource: LevelLocalDataSource {
        get { self[LevelLocalDataSource.self] }
        set { self[LevelLocalDataSource.self] = newValue }
    }
}
