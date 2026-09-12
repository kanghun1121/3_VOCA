import SwiftData

struct ChatMessagePayload: Codable {
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
