import Foundation
import SwiftData

import Dependencies

/// `LessonEntity`+`LessonWordEntity`(조인)만 소유한다. 단어 상세는 전혀 모른다 — 레슨에 속한
/// 단어를 실제로 조립하는 건 `WordLocalDataSource`를 함께 쓰는 `LessonRepository+Live`의 몫이다.
struct LessonLocalDataSource: Sendable {
    @Dependency(\.localDatabaseContext) private var context

    func lesson(id: Int) async throws -> LessonEntity? {
        try await context.fetch(FetchDescriptor<LessonEntity>(
            predicate: #Predicate { $0.id == id }
        )).first
    }

    /// lessonNumber 오름차순 — LearningLibrary 레벨 안에서 레슨이 노출되는 순서다.
    func lessons(levelID: Int) async throws -> [LessonEntity] {
        try await context.fetch(FetchDescriptor<LessonEntity>(
            predicate: #Predicate { $0.levelID == levelID },
            sortBy: [SortDescriptor(\.lessonNumber)]
        ))
    }

    /// position 오름차순으로 정렬된 단어 id 목록 — WordGame/단어장 화면에 노출되는 순서다.
    func orderedWordIDs(lessonID: Int) async throws -> [Int] {
        let joins = try await context.fetch(FetchDescriptor<LessonWordEntity>(
            predicate: #Predicate { $0.lessonID == lessonID },
            sortBy: [SortDescriptor(\.position)]
        ))
        return joins.map(\.wordID)
    }

    func insertLessons(_ lessons: [LessonEntity]) async {
        for lesson in lessons { await context.insert(lesson) }
    }

    func insertLessonWords(_ lessonWords: [LessonWordEntity]) async {
        for lessonWord in lessonWords { await context.insert(lessonWord) }
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
