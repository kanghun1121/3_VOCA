import Foundation

/// `wordID`/`conversationID`는 상호 배타적이다 — `conversationID`가 있으면(같은 화면 방문의
/// 두 번째 이후 전송) `wordID`는 nil로 보내 생략한다(서버 스펙: "conversation_id 사용 시
/// word_id 생략 가능"). Optional 프로퍼티는 synthesized Encodable이 encodeIfPresent로
/// 처리하므로 nil이면 JSON 키 자체가 안 실린다.
struct ChatProxyRequestBody: Encodable {
    let stream = true
    let messages: [ChatProxyMessage]
    let sseID: String
    let wordID: String?
    let conversationID: String?

    private enum CodingKeys: String, CodingKey {
        case stream
        case messages
        case sseID = "sse_id"
        case wordID = "word_id"
        case conversationID = "conversation_id"
    }
}
