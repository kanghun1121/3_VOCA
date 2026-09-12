import XCTest

@testable import Data

final class ChatHistoryResponseDTOTests: XCTestCase {
    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    private let sampleJSON = """
    {
        "word_id": 978,
        "conversations": [
            {
                "conversation_id": "eb05cb35-80c4-478b-942d-b046e4c31a54",
                "created_at": "2026-09-10T14:03:24.494174+00:00",
                "messages": [
                    {
                        "id": 17,
                        "role": "user",
                        "content": "123123123123123",
                        "created_at": "2026-09-10T14:03:24.622755+00:00"
                    },
                    {
                        "id": 18,
                        "role": "assistant",
                        "content": "# 123123123123123",
                        "created_at": "2026-09-10T14:03:27.362565+00:00"
                    }
                ]
            },
            {
                "conversation_id": "70bfda62-c482-442f-b09b-38ac2a36a5da",
                "created_at": "2026-09-10T14:03:10.877719+00:00",
                "messages": [
                    {
                        "id": 15,
                        "role": "user",
                        "content": "123",
                        "created_at": "2026-09-10T14:03:10.904047+00:00"
                    },
                    {
                        "id": 16,
                        "role": "assistant",
                        "content": "# 123",
                        "created_at": "2026-09-10T14:03:12.356586+00:00"
                    }
                ]
            }
        ]
    }
    """

    func test_실제_응답_예시를_디코딩하면_사용하는_필드만_정확히_매핑된다() throws {
        let data = try XCTUnwrap(sampleJSON.data(using: .utf8))

        let dto = try makeDecoder().decode(ChatHistoryResponseDTO.self, from: data)

        XCTAssertEqual(dto.conversations.count, 2)

        let first = dto.conversations[0]
        XCTAssertEqual(first.messages.count, 2)

        let firstMessage = first.messages[0]
        XCTAssertEqual(firstMessage.role, "user")
        XCTAssertEqual(firstMessage.content, "123123123123123")

        let secondMessage = first.messages[1]
        XCTAssertEqual(secondMessage.role, "assistant")
    }
}
