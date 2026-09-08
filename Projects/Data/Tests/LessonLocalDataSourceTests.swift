import XCTest

@testable import Data

final class LessonLocalDataSourceTests: XCTestCase {
    func test_존재하지_않는_레슨_id를_조회하면_nil을_반환한다() async throws {
        let db = LocalDatabaseTestContext()

        let result = try await db.run {
            try await LessonLocalDataSource().lesson(id: 999_999)
        }

        XCTAssertNil(result)
    }

    func test_lessons_levelID는_삽입_순서와_무관하게_lessonNumber_오름차순으로_반환된다() async throws {
        let db = LocalDatabaseTestContext()
        try await db.seed(
            LessonEntity(id: 2, levelID: 1, lessonNumber: 2, orderedWordIDs: [1]),
            LessonEntity(id: 1, levelID: 1, lessonNumber: 1, orderedWordIDs: [1]),
            LessonEntity(id: 3, levelID: 2, lessonNumber: 1, orderedWordIDs: [1])
        )

        let lessons = try await db.run {
            try await LessonLocalDataSource().lessons(levelID: 1)
        }

        XCTAssertEqual(lessons.map(\.lessonNumber), [1, 2])
    }
}
