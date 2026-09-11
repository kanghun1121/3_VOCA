import Foundation

/// HTTPClient의 공유 JSONDecoder가 keyDecodingStrategy = .convertFromSnakeCase를 쓴다 — 그래서
/// 프로퍼티명은 "wordId"처럼 변환 후 형태(camelCase)를 그대로 써야 한다. "wordID"처럼 두 글자를
/// 대문자로 쓰거나 CodingKeys에 원본 snake_case("word_id")를 직접 매핑하면, 디코더가 이미
/// "word_id"를 "wordId"로 바꿔버린 뒤라 그 키를 못 찾아 디코딩이 실패한다(KeyDecodingStrategy는
/// CodingKeys보다 먼저 적용된다). 그래서 이 파일은 커스텀 CodingKeys 없이 AuthTokenResponseDTO와
/// 동일한 방식(순수 synthesized Decodable)을 쓴다.
///
/// 서버 응답에는 word_id/conversation_id/created_at 필드도 실려 오지만, 클라이언트는 여러
/// conversation의 메시지를 전부 평탄화한 단일 히스토리로만 쓰고 그 외 필드는 어디서도 읽지
/// 않는다. Decodable은 선언하지 않은 키를 무시하므로, 안 쓰는 필드는 DTO에 아예 선언하지 않는다.
struct ChatHistoryResponseDTO: Decodable {
    let conversations: [ChatConversationDTO]
}

struct ChatConversationDTO: Decodable {
    let messages: [ChatHistoryMessageDTO]
}

struct ChatHistoryMessageDTO: Decodable {
    let id: Int
    let role: String
    let content: String
}
