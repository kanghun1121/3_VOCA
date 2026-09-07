import SwiftData
import XCTest

import DomainInterface
import Dependencies
@testable import Data

/// `LessonRepository.liveValue`가 Lesson/Level/Word 3개 LocalDataSource를 조합해 `Lesson`을
/// 조립하는 로직 — 각 DataSource는 서로를 모르므로, 이 조합 자체가 새로 생긴 판단 지점이다.
final class LessonRepositoryLiveTests: XCTestCase {
    private func makeContext() -> LocalDatabaseContext {
        LocalDatabaseContext(modelContainer: LocalDatabaseSchema.makeInMemoryContainer())
    }

    func test_레슨_조회시_단어가_position_순으로_조립되고_레벨의_cefr등급이_반영된다() async throws {
        let context = makeContext()
        await context.insert(LevelEntity(id: 1, nameKo: "씨앗", cefrLabel: "A1", sortOrder: 1))
        await context.insert(LessonEntity(id: 5, levelID: 1, lessonNumber: 1, wordCount: 2))
        await context.insert(WordEntity(id: 10, word: "b", levelID: 1, pronunciation: "", audioUrl: "", distractors: []))
        await context.insert(WordEntity(id: 20, word: "a", levelID: 1, pronunciation: "", audioUrl: "", distractors: []))
        // 일부러 position 역순으로 삽입한다.
        await context.insert(LessonWordEntity(lessonID: 5, wordID: 10, position: 2))
        await context.insert(LessonWordEntity(lessonID: 5, wordID: 20, position: 1))
        try await context.save()

        let lesson = try await withDependencies {
            $0.localDatabaseContext = context
        } operation: {
            try await LessonRepository.liveValue.fetchDetail("5")
        }

        XCTAssertEqual(lesson.words.map(\.term), ["a", "b"])
        XCTAssertEqual(lesson.cefrLevel, "A1")
        XCTAssertEqual(lesson.level, 1)
    }

    func test_존재하지_않는_레슨_id면_lessonNotFound를_던진다() async {
        let context = makeContext()

        do {
            try await withDependencies {
                $0.localDatabaseContext = context
            } operation: {
                _ = try await LessonRepository.liveValue.fetchDetail("999999")
            }
            XCTFail("에러를 던졌어야 한다")
        } catch LocalDatabaseError.lessonNotFound(999_999) {
        } catch {
            XCTFail("예상과 다른 에러: \(error)")
        }
    }
}
