import Foundation
import SwiftData

import Dependencies

/// `LessonEntity`(정렬된 단어 id 목록 포함)만 소유한다. 단어 상세는 전혀 모른다 — 레슨에 속한
/// 단어를 실제로 조립하는 건 `WordLocalDataSource`를 함께 쓰는 `LessonRepository+Live`의 몫이다.
struct LessonLocalDataSource: Sendable {
    @Dependency(\.localDatabaseContext) private var context

    func lesson(id: Int) async throws -> LessonEntity? {
        try await context.fetch(FetchDescriptor<LessonEntity>(
            predicate: #Predicate { $0.id == id }
        )).first
    }

    /// lessonNumber 오름차순 — VocabularyLibrary 레벨 안에서 레슨이 노출되는 순서다.
    func lessons(levelID: Int) async throws -> [LessonEntity] {
        try await context.fetch(FetchDescriptor<LessonEntity>(
            predicate: #Predicate { $0.levelID == levelID },
            sortBy: [SortDescriptor(\.lessonNumber)]
        ))
    }

    func insertLessons(_ lessons: [LessonEntity]) async {
        for lesson in lessons { await context.insert(lesson) }
    }
}

extension LessonLocalDataSource: DependencyKey {
    static let liveValue = LessonLocalDataSource()
}

extension LessonLocalDataSource: TestDependencyKey {
    static let testValue = LessonLocalDataSource()
}

extension DependencyValues {
    var lessonLocalDataSource: LessonLocalDataSource {
        get { self[LessonLocalDataSource.self] }
        set { self[LessonLocalDataSource.self] = newValue }
    }
}
