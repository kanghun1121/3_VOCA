import SwiftData
import XCTest

import Dependencies
@testable import Data

/// `VocabularyLibraryRepository+Live.swift`의 `localSkeleton()` — Level+Lesson
/// LocalDataSource를 조합해 정적 구조를 조립하는, 이번에 새로 생긴 판단 로직이다.
final class VocabularyLibraryLocalSkeletonTests: XCTestCase {
    func test_레벨과_레슨을_조합해_정적_스켈레톤을_조립하고_진행상태는_전부_기본값이다() async throws {
        let context = LocalDatabaseContext(modelContainer: LocalDatabaseSchema.makeInMemoryContainer())
        await context.insert(LevelEntity(id: 2, nameKo: "새싹", cefrLabel: "A2", sortOrder: 2))
        await context.insert(LevelEntity(id: 1, nameKo: "씨앗", cefrLabel: "A1", sortOrder: 1))
        await context.insert(LessonEntity(id: 1, levelID: 1, lessonNumber: 1, wordCount: 20))
        try await context.save()

        let summaries = try await withDependencies {
            $0.localDatabaseContext = context
        } operation: {
            try await localSkeleton()
        }

        XCTAssertEqual(summaries.map(\.name), ["씨앗", "새싹"])
        XCTAssertEqual(summaries[0].completedLessons, 0)
        XCTAssertEqual(summaries[0].lessons.first?.status, .notStarted)
        XCTAssertTrue(summaries[1].lessons.isEmpty)
    }
}
