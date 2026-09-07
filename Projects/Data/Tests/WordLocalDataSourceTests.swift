import SwiftData
import XCTest

import Dependencies
@testable import Data

final class WordLocalDataSourceTests: XCTestCase {
    private func makeContext() -> LocalDatabaseContext {
        LocalDatabaseContext(modelContainer: LocalDatabaseSchema.makeInMemoryContainer())
    }

    func test_존재하지_않는_단어_id를_조회하면_wordNotFound를_던진다() async {
        let context = makeContext()

        do {
            try await withDependencies {
                $0.localDatabaseContext = context
            } operation: {
                _ = try await WordLocalDataSource().wordDetail(id: 999_999)
            }
            XCTFail("에러를 던졌어야 한다")
        } catch LocalDatabaseError.wordNotFound(999_999) {
        } catch {
            XCTFail("예상과 다른 에러: \(error)")
        }
    }

    func test_단어_뜻은_삽입_순서와_무관하게_rank_오름차순으로_반환된다() async throws {
        let context = makeContext()
        await context.insert(WordEntity(id: 1, word: "test", levelID: 1, pronunciation: "", audioUrl: "", distractors: []))
        // 일부러 rank 역순으로 삽입해 정렬이 삽입 순서에 우연히 의존하지 않는지 확인한다.
        await context.insert(WordMeaningEntity(id: 1, wordID: 1, pos: "noun", ko: "세번째", rank: 3))
        await context.insert(WordMeaningEntity(id: 2, wordID: 1, pos: "noun", ko: "첫번째", rank: 1))
        await context.insert(WordMeaningEntity(id: 3, wordID: 1, pos: "noun", ko: "두번째", rank: 2))
        try await context.save()

        let detail = try await withDependencies {
            $0.localDatabaseContext = context
        } operation: {
            try await WordLocalDataSource().wordDetail(id: 1)
        }

        XCTAssertEqual(detail.definitions.map(\.meaning), ["첫번째", "두번째", "세번째"])
    }

    func test_lessonWords는_요청한_id들의_단어를_뜻과_함께_반환한다() async throws {
        let context = makeContext()
        await context.insert(WordEntity(id: 10, word: "b", levelID: 1, pronunciation: "", audioUrl: "", distractors: ["x"]))
        await context.insert(WordEntity(id: 20, word: "a", levelID: 1, pronunciation: "", audioUrl: "", distractors: []))
        await context.insert(WordMeaningEntity(id: 1, wordID: 10, pos: "noun", ko: "비", rank: 1))
        try await context.save()

        let result = try await withDependencies {
            $0.localDatabaseContext = context
        } operation: {
            try await WordLocalDataSource().lessonWords(ids: [10, 20])
        }

        XCTAssertEqual(result[10]?.term, "b")
        XCTAssertEqual(result[10]?.definitions.map(\.meaning), ["비"])
        XCTAssertEqual(result[20]?.term, "a")
        XCTAssertEqual(result[20]?.definitions, [])
    }

    func test_lessonWords에_빈_id_배열을_주면_빈_딕셔너리를_반환한다() async throws {
        let context = makeContext()

        let result = try await withDependencies {
            $0.localDatabaseContext = context
        } operation: {
            try await WordLocalDataSource().lessonWords(ids: [])
        }

        XCTAssertTrue(result.isEmpty)
    }
}
