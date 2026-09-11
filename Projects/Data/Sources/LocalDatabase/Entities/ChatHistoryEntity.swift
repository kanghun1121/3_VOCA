import SwiftData

/// 챗봇 대화 메시지는 항상 단어(wordID) 하나의 히스토리 전체 단위로 읽고 쓴다 — 메시지 하나만
/// 개별 조회/갱신하는 경우가 없어, 메시지별 행이 아니라 `WordExampleEntity`/`ExampleWordPayload`와
/// 동일한 방식(엔티티 하나 + 그 안의 Codable 값 타입 배열)으로 저장한다.
struct ChatMessagePayload: Codable {
    let id: Int
    let role: String
    let content: String
}

@Model
final class ChatHistoryEntity {
    @Attribute(.unique) var wordID: String
    var messages: [ChatMessagePayload]

    init(wordID: String, messages: [ChatMessagePayload]) {
        self.wordID = wordID
        self.messages = messages
    }
}
