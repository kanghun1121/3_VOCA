import XCTest

@testable import Data

final class ChatHistoryLocalDataSourceTests: XCTestCase {
    func test_캐시된_행이_없으면_빈_배열을_반환한다() async throws {
        let db = LocalDatabaseTestContext()

        let messages = try await db.run {
            try await ChatHistoryLocalDataSource().messages(wordID: "word_001")
        }

        XCTAssertTrue(messages.isEmpty)
    }

    func test_저장_후_조회하면_저장한_순서_그대로_반환한다() async throws {
        let db = LocalDatabaseTestContext()
        let payloads = [
            ChatMessagePayload(id: 1, role: "user", content: "질문"),
            ChatMessagePayload(id: 2, role: "assistant", content: "답변"),
        ]

        try await db.run {
            try await ChatHistoryLocalDataSource().save(wordID: "word_001", messages: payloads)
        }
        let messages = try await db.run {
            try await ChatHistoryLocalDataSource().messages(wordID: "word_001")
        }

        XCTAssertEqual(messages.map(\.id), [1, 2])
        XCTAssertEqual(messages.map(\.content), ["질문", "답변"])
    }

    func test_같은_wordID로_다시_저장하면_이전_내용이_아니라_완전히_교체된다() async throws {
        let db = LocalDatabaseTestContext()
        let firstSave = [ChatMessagePayload(id: 1, role: "user", content: "첫 질문")]
        let secondSave = [
            ChatMessagePayload(id: 1, role: "user", content: "첫 질문"),
            ChatMessagePayload(id: 2, role: "assistant", content: "첫 답변"),
        ]

        try await db.run {
            let dataSource = ChatHistoryLocalDataSource()
            try await dataSource.save(wordID: "word_001", messages: firstSave)
            try await dataSource.save(wordID: "word_001", messages: secondSave)
        }
        let messages = try await db.run {
            try await ChatHistoryLocalDataSource().messages(wordID: "word_001")
        }

        // "첫 질문"이 중복으로 남지 않고, 두 번째 save가 준 배열로 정확히 교체됐어야 한다.
        XCTAssertEqual(messages.map(\.id), [1, 2])
    }

    func test_다른_wordID의_데이터는_섞이지_않는다() async throws {
        let db = LocalDatabaseTestContext()

        try await db.run {
            let dataSource = ChatHistoryLocalDataSource()
            try await dataSource.save(wordID: "word_001", messages: [ChatMessagePayload(id: 1, role: "user", content: "word_001 질문")])
            try await dataSource.save(wordID: "word_002", messages: [ChatMessagePayload(id: 2, role: "user", content: "word_002 질문")])
        }

        let word1Messages = try await db.run { try await ChatHistoryLocalDataSource().messages(wordID: "word_001") }
        let word2Messages = try await db.run { try await ChatHistoryLocalDataSource().messages(wordID: "word_002") }

        XCTAssertEqual(word1Messages.map(\.content), ["word_001 질문"])
        XCTAssertEqual(word2Messages.map(\.content), ["word_002 질문"])
    }
}
