import XCTest

import DomainInterface

@testable import Data

final class ChatHistoryResponseDTOMappingTests: XCTestCase {
    private func makeMessageDTO(
        id: Int = 1,
        role: String = "user",
        content: String = "hello"
    ) -> ChatHistoryMessageDTO {
        ChatHistoryMessageDTO(id: id, role: role, content: content)
    }

    func test_여러_conversation의_메시지를_하나로_평탄화해_순서대로_매핑한다() throws {
        let dto = ChatHistoryResponseDTO(
            conversations: [
                ChatConversationDTO(messages: [
                    makeMessageDTO(id: 17, role: "user", content: "123123123123123"),
                    makeMessageDTO(id: 18, role: "assistant", content: "# 123123123123123")
                ]),
                ChatConversationDTO(messages: [
                    makeMessageDTO(id: 15, role: "user", content: "123"),
                    makeMessageDTO(id: 16, role: "assistant", content: "# 123")
                ])
            ]
        )

        let domain = try dto.toDomain()

        XCTAssertEqual(domain.messages.map(\.id), [17, 18, 15, 16])
        XCTAssertEqual(domain.messages.map(\.role), [.user, .assistant, .user, .assistant])
        XCTAssertEqual(domain.messages.map(\.content), ["123123123123123", "# 123123123123123", "123", "# 123"])
    }

    func test_알수없는_role이면_invalidRole_에러를_던진다() {
        let dto = makeMessageDTO(role: "system")

        XCTAssertThrowsError(try dto.toDomain()) { error in
            XCTAssertEqual(error as? ChatHistoryMappingError, .invalidRole("system"))
        }
    }
}
