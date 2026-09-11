import XCTest

import DomainInterface

@testable import Data

final class ChatMessagePayloadMappingTests: XCTestCase {
    func test_유효한_role이면_Domain_Message로_변환된다() throws {
        let payload = ChatMessagePayload(id: 1, role: "assistant", content: "답변")

        let message = try payload.toDomain()

        XCTAssertEqual(message.id, 1)
        XCTAssertEqual(message.role, .assistant)
        XCTAssertEqual(message.content, "답변")
    }

    func test_알수없는_role이면_invalidRole_에러를_던진다() {
        let payload = ChatMessagePayload(id: 1, role: "system", content: "답변")

        XCTAssertThrowsError(try payload.toDomain()) { error in
            XCTAssertEqual(error as? ChatHistoryMappingError, .invalidRole("system"))
        }
    }

    func test_Domain_Message는_asPayload로_왕복_변환된다() {
        let message = ChatHistory.Message(id: 7, role: .user, content: "질문")

        let payload = message.asPayload

        XCTAssertEqual(payload.id, 7)
        XCTAssertEqual(payload.role, "user")
        XCTAssertEqual(payload.content, "질문")
    }
}
