import SwiftData
import XCTest

@testable import Data

/// 번들에 실제로 들어가는 시드 JSON 7개를 그대로 파싱/삽입해, 스키마와 실제 데이터가
/// 어긋나지 않는지 검증한다(정렬은 각 도메인 LocalDataSource의 책임이라 여기서는 다루지 않는다).
final class LocalDatabaseSeederTests: XCTestCase {
    private func seed() async throws -> LocalDatabaseTestContext {
        let db = LocalDatabaseTestContext()
        try await db.run {
            try await LocalDatabaseSeeder.seed(
                word: WordLocalDataSource(),
                lesson: LessonLocalDataSource(),
                level: LevelLocalDataSource(),
                context: db.context
            )
        }
        return db
    }

    func test_정상_시딩하면_7개_테이블_건수가_실제_시드_파일과_일치한다() async throws {
        let db = try await seed()

        let levelCount = try await db.count(LevelEntity.self)
        let lessons = try await db.context.fetch(FetchDescriptor<LessonEntity>())
        let lessonCount = lessons.count
        // LessonWordEntity가 LessonEntity.orderedWordIDs 배열로 흡수되어 더 이상 독립
        // 테이블이 아니므로, 각 레슨의 배열 길이를 합산해 같은 의미의 회귀 가드를 구성한다.
        let lessonWordCount = lessons.reduce(0) { $0 + $1.orderedWordIDs.count }
        let words = try await db.context.fetch(FetchDescriptor<WordEntity>())
        let wordCount = words.count
        // WordMeaningEntity가 WordEntity.meanings 배열로 흡수되어 더 이상 독립 테이블이
        // 아니므로, 각 단어의 배열 길이를 합산해 같은 의미의 회귀 가드를 구성한다.
        let meaningCount = words.reduce(0) { $0 + $1.meanings.count }
        let exampleCount = try await db.count(WordExampleEntity.self)

        XCTAssertEqual(levelCount, 6)
        XCTAssertEqual(lessonCount, 244)
        XCTAssertEqual(lessonWordCount, 4834)
        XCTAssertEqual(wordCount, 4834)
        XCTAssertEqual(meaningCount, 7376)
        XCTAssertEqual(exampleCount, 9668)
    }

    func test_단어와_오답_선택지가_word_id_기준으로_정확히_결합된다() async throws {
        let db = try await seed()

        let words = try await db.context.fetch(FetchDescriptor<WordEntity>(predicate: #Predicate { $0.id == 1 }))
        let word = try XCTUnwrap(words.first)

        XCTAssertEqual(word.word, "an")
        XCTAssertTrue(word.audioUrl.hasSuffix("an.mp3"))
        XCTAssertEqual(word.distractors, ["모든", "여러 개의", "어떤"])
    }

    func test_한_단어에_여러_뜻이_있으면_전부_삽입된다() async throws {
        let db = try await seed()

        let words = try await db.context.fetch(FetchDescriptor<WordEntity>(predicate: #Predicate { $0.id == 23 }))
        let word = try XCTUnwrap(words.first)

        XCTAssertEqual(word.meanings.count, 3)
    }

    func test_뜻이_4개인_단어의_meanings가_rank_오름차순으로_저장된다() async throws {
        let db = try await seed()

        // word_meanings.json에서 실제로 뜻이 4개(단어당 최대 개수)인 단어(word_id: 2900).
        let words = try await db.context.fetch(FetchDescriptor<WordEntity>(predicate: #Predicate { $0.id == 2900 }))
        let word = try XCTUnwrap(words.first)

        XCTAssertEqual(word.meanings.count, 4)
        XCTAssertEqual(word.meanings.map(\.rank), word.meanings.map(\.rank).sorted())
    }

    func test_레슨의_orderedWordIDs가_시드_position_오름차순과_일치한다() async throws {
        let db = try await seed()

        let lessons = try await db.context.fetch(FetchDescriptor<LessonEntity>(predicate: #Predicate { $0.id == 1 }))
        let lesson = try XCTUnwrap(lessons.first)

        // lesson_words.json에서 lesson_id == 1을 position 오름차순으로 정렬한 wordID 목록과 동일해야 한다.
        XCTAssertEqual(lesson.orderedWordIDs, [
            765, 250, 1328, 1162, 1072, 2070, 1723, 1284, 2847, 970,
            2476, 1868, 1166, 2000, 2572, 1421, 2530, 200, 2162, 1319,
        ])
    }

    /// #106 리팩토링 전에는 `LessonWordEntity`(유니크 키 없음)가 중복 재삽입 위험을
    /// 안고 있었다 — 재시딩 시 이 엔티티만 조용히 중복될 수 있었다(Decision B). 이제는
    /// `LessonEntity.orderedWordIDs`(유니크 id를 가진 엔티티의 속성)로 흡수되어, 시더를
    /// 몇 번 다시 돌려도 upsert만 일어나야 한다.
    func test_시더를_두번_실행해도_레코드_수가_그대로_유지된다() async throws {
        let db = try await seed()
        try await db.run {
            try await LocalDatabaseSeeder.seed(
                word: WordLocalDataSource(),
                lesson: LessonLocalDataSource(),
                level: LevelLocalDataSource(),
                context: db.context
            )
        }

        let levelCount = try await db.count(LevelEntity.self)
        let lessons = try await db.context.fetch(FetchDescriptor<LessonEntity>())
        let words = try await db.context.fetch(FetchDescriptor<WordEntity>())
        let exampleCount = try await db.count(WordExampleEntity.self)

        XCTAssertEqual(levelCount, 6)
        XCTAssertEqual(lessons.count, 244)
        XCTAssertEqual(lessons.reduce(0) { $0 + $1.orderedWordIDs.count }, 4834)
        XCTAssertEqual(words.count, 4834)
        XCTAssertEqual(words.reduce(0) { $0 + $1.meanings.count }, 7376)
        XCTAssertEqual(exampleCount, 9668)
    }

    func test_예문의_words_chunks가_그대로_보존된다() async throws {
        let db = try await seed()

        let examples = try await db.context.fetch(FetchDescriptor<WordExampleEntity>(predicate: #Predicate { $0.id == 1 }))
        let example = try XCTUnwrap(examples.first)

        XCTAssertEqual(example.sentenceEn, "I have an apple in my bag.")
        XCTAssertFalse(example.words.isEmpty)
        XCTAssertFalse(example.chunks.isEmpty)
    }
}
