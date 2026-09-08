import XCTest

import DomainInterface
@testable import Data

/// `LessonRepository.liveValue`가 Lesson/Level/Word 3개 LocalDataSource를 조합해 `Lesson`을
/// 조립하는 로직 — 각 DataSource는 서로를 모르므로, 이 조합 자체가 새로 생긴 판단 지점이다.
final class LessonRepositoryLiveTests: XCTestCase {
    func test_레슨_조회시_단어가_position_순으로_조립되고_레벨의_cefr등급이_반영된다() async throws {
        let db = LocalDatabaseTestContext()
        // orderedWordIDs 배열 리터럴 순서가 곧 position 순서다 — 일부러 단어 삽입 순서와
        // 다르게 배열 순서를 정해 정렬이 삽입 순서에 우연히 의존하지 않는지 확인한다.
        try await db.seed(
            LevelEntity(id: 1, nameKo: "씨앗", cefrLabel: "A1", sortOrder: 1),
            LessonEntity(id: 5, levelID: 1, lessonNumber: 1, orderedWordIDs: [20, 10]),
            WordEntity(id: 10, word: "b", levelID: 1, pronunciation: "", audioUrl: "", distractors: []),
            WordEntity(id: 20, word: "a", levelID: 1, pronunciation: "", audioUrl: "", distractors: [])
        )

        let lesson = try await db.run {
            try await LessonRepository.liveValue.fetchDetail("5")
        }

        XCTAssertEqual(lesson.words.map(\.term), ["a", "b"])
        XCTAssertEqual(lesson.cefrLevel, "A1")
        XCTAssertEqual(lesson.level, 1)
    }

    func test_orderedWordIDs가_비어있으면_words도_빈_배열이다() async throws {
        let db = LocalDatabaseTestContext()
        try await db.seed(
            LevelEntity(id: 1, nameKo: "씨앗", cefrLabel: "A1", sortOrder: 1),
            LessonEntity(id: 5, levelID: 1, lessonNumber: 1, orderedWordIDs: [])
        )

        let lesson = try await db.run {
            try await LessonRepository.liveValue.fetchDetail("5")
        }

        XCTAssertTrue(lesson.words.isEmpty)
    }

    func test_존재하지_않는_레슨_id면_lessonNotFound를_던진다() async {
        let db = LocalDatabaseTestContext()

        do {
            try await db.run {
                _ = try await LessonRepository.liveValue.fetchDetail("999999")
            }
            XCTFail("에러를 던졌어야 한다")
        } catch LocalDatabaseError.lessonNotFound(999_999) {
        } catch {
            XCTFail("예상과 다른 에러: \(error)")
        }
    }
}
