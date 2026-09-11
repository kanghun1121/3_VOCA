import XCTest

@testable import Data

final class ChatSessionStoreTests: XCTestCase {
    func test_beginSend는_비어있지_않은_sseID를_발급하고_activeSSEID로_조회된다() async {
        let store = ChatSessionStore()

        let sseID = await store.beginSend(wordID: "word_001")

        XCTAssertFalse(sseID.isEmpty)
        let activeSSEID = await store.activeSSEID(for: "word_001")
        XCTAssertEqual(activeSSEID, sseID)
    }

    func test_endSend_이후에는_activeSSEID가_nil이다() async {
        let store = ChatSessionStore()
        _ = await store.beginSend(wordID: "word_001")

        await store.endSend(wordID: "word_001")

        let activeSSEID = await store.activeSSEID(for: "word_001")
        XCTAssertNil(activeSSEID)
    }

    func test_진행중인_전송이_없으면_activeSSEID는_nil이다() async {
        let store = ChatSessionStore()

        let activeSSEID = await store.activeSSEID(for: "word_001")

        XCTAssertNil(activeSSEID)
    }

    func test_conversationID는_처음엔_nil이고_setConversationID_이후_그대로_조회된다() async {
        let store = ChatSessionStore()

        let before = await store.conversationID(for: "word_001")
        XCTAssertNil(before)

        await store.setConversationID("conv-001", wordID: "word_001")

        let after = await store.conversationID(for: "word_001")
        XCTAssertEqual(after, "conv-001")
    }

    func test_다른_wordID의_세션_상태는_서로_섞이지_않는다() async {
        let store = ChatSessionStore()

        let sseID1 = await store.beginSend(wordID: "word_001")
        await store.setConversationID("conv-001", wordID: "word_001")

        let activeSSEID2 = await store.activeSSEID(for: "word_002")
        let conversationID2 = await store.conversationID(for: "word_002")

        XCTAssertNil(activeSSEID2)
        XCTAssertNil(conversationID2)
        let activeSSEID1 = await store.activeSSEID(for: "word_001")
        XCTAssertEqual(activeSSEID1, sseID1)
    }
}
