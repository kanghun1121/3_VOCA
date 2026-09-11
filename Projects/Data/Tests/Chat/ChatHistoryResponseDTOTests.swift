import XCTest

@testable import Data

final class ChatHistoryResponseDTOTests: XCTestCase {
    /// HTTPClient가 실제로 쓰는 디코더와 동일하게 구성한다(keyDecodingStrategy = .convertFromSnakeCase).
    /// 이 설정 없이 바닐라 JSONDecoder()로 디코딩하면, DTO가 실제 운영 경로에서 깨지는 걸
    /// 테스트가 놓친다 — 실제로 한 번 이 문제로 word_id 디코딩이 런타임에 실패했었다.
    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    /// 실제 서버 응답 예시(2개 대화, 각 대화에 user/assistant 메시지 1쌍씩) — conversation_id/
    /// created_at처럼 DTO가 선언하지 않은 필드도 그대로 포함해, 안 쓰는 필드가 있어도 디코딩이
    /// 깨지지 않는지(Decodable이 여분의 키를 무시하는지) 함께 확인한다.
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
        XCTAssertEqual(firstMessage.id, 17)
        XCTAssertEqual(firstMessage.role, "user")
        XCTAssertEqual(firstMessage.content, "123123123123123")

        let secondMessage = first.messages[1]
        XCTAssertEqual(secondMessage.role, "assistant")
    }
}
