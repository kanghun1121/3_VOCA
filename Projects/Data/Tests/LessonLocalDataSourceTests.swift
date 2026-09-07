import SwiftData
import XCTest

import Dependencies
@testable import Data

final class LessonLocalDataSourceTests: XCTestCase {
    private func makeContext() -> LocalDatabaseContext {
        LocalDatabaseContext(modelContainer: LocalDatabaseSchema.makeInMemoryContainer())
    }

    func test_존재하지_않는_레슨_id를_조회하면_nil을_반환한다() async throws {
        let context = makeContext()

        let result = try await withDependencies {
            $0.localDatabaseContext = context
        } operation: {
            try await LessonLocalDataSource().lesson(id: 999_999)
        }

        XCTAssertNil(result)
    }

    func test_orderedWordIDs는_삽입_순서와_무관하게_position_오름차순으로_반환된다() async throws {
        let context = makeContext()
        // 일부러 position 역순으로 삽입한다.
        await context.insert(LessonWordEntity(lessonID: 1, wordID: 10, position: 2))
        await context.insert(LessonWordEntity(lessonID: 1, wordID: 20, position: 1))
        try await context.save()

        let ids = try await withDependencies {
            $0.localDatabaseContext = context
        } operation: {
            try await LessonLocalDataSource().orderedWordIDs(lessonID: 1)
        }

        XCTAssertEqual(ids, [20, 10])
    }

    func test_lessons_levelID는_삽입_순서와_무관하게_lessonNumber_오름차순으로_반환된다() async throws {
        let context = makeContext()
        await context.insert(LessonEntity(id: 2, levelID: 1, lessonNumber: 2, wordCount: 20))
        await context.insert(LessonEntity(id: 1, levelID: 1, lessonNumber: 1, wordCount: 20))
        await context.insert(LessonEntity(id: 3, levelID: 2, lessonNumber: 1, wordCount: 20))
        try await context.save()

        let lessons = try await withDependencies {
            $0.localDatabaseContext = context
        } operation: {
            try await LessonLocalDataSource().lessons(levelID: 1)
        }

        XCTAssertEqual(lessons.map(\.lessonNumber), [1, 2])
    }
}
