import SwiftData
import XCTest

import Dependencies
@testable import Data

/// 번들에 실제로 들어가는 시드 JSON 7개를 그대로 파싱/삽입해, 스키마와 실제 데이터가
/// 어긋나지 않는지 검증한다(정렬은 각 도메인 LocalDataSource의 책임이라 여기서는 다루지 않는다).
final class LocalDatabaseSeederTests: XCTestCase {
    private func seed() async throws -> LocalDatabaseContext {
        let context = LocalDatabaseContext(modelContainer: LocalDatabaseSchema.makeInMemoryContainer())
        try await withDependencies {
            $0.localDatabaseContext = context
        } operation: {
            try await LocalDatabaseSeeder.seed(
                word: WordLocalDataSource(),
                lesson: LessonLocalDataSource(),
                level: LevelLocalDataSource(),
                context: context
            )
        }
        return context
    }

    func test_정상_시딩하면_7개_테이블_건수가_실제_시드_파일과_일치한다() async throws {
        let context = try await seed()

        let levelCount = try await context.fetch(FetchDescriptor<LevelEntity>()).count
        let lessonCount = try await context.fetch(FetchDescriptor<LessonEntity>()).count
        let lessonWordCount = try await context.fetch(FetchDescriptor<LessonWordEntity>()).count
        let wordCount = try await context.fetch(FetchDescriptor<WordEntity>()).count
        let meaningCount = try await context.fetch(FetchDescriptor<WordMeaningEntity>()).count
        let exampleCount = try await context.fetch(FetchDescriptor<WordExampleEntity>()).count

        XCTAssertEqual(levelCount, 6)
        XCTAssertEqual(lessonCount, 244)
        XCTAssertEqual(lessonWordCount, 4834)
        XCTAssertEqual(wordCount, 4834)
        XCTAssertEqual(meaningCount, 7376)
        XCTAssertEqual(exampleCount, 9668)
    }

    func test_단어와_오답_선택지가_word_id_기준으로_정확히_결합된다() async throws {
        let context = try await seed()

        let words = try await context.fetch(FetchDescriptor<WordEntity>(predicate: #Predicate { $0.id == 1 }))
        let word = try XCTUnwrap(words.first)

        XCTAssertEqual(word.word, "an")
        XCTAssertTrue(word.audioUrl.hasSuffix("an.mp3"))
        XCTAssertEqual(word.distractors, ["모든", "여러 개의", "어떤"])
    }

    func test_한_단어에_여러_뜻이_있으면_전부_삽입된다() async throws {
        let context = try await seed()

        let meanings = try await context.fetch(FetchDescriptor<WordMeaningEntity>(
            predicate: #Predicate { $0.wordID == 23 }
        ))

        XCTAssertEqual(meanings.count, 3)
    }

    func test_예문의_words_chunks가_그대로_보존된다() async throws {
        let context = try await seed()

        let examples = try await context.fetch(FetchDescriptor<WordExampleEntity>(predicate: #Predicate { $0.id == 1 }))
        let example = try XCTUnwrap(examples.first)

        XCTAssertEqual(example.sentenceEn, "I have an apple in my bag.")
        XCTAssertFalse(example.words.isEmpty)
        XCTAssertFalse(example.chunks.isEmpty)
    }
}
