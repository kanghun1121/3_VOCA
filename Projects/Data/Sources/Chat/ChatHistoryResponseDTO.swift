import Foundation

struct ChatHistoryResponseDTO: Decodable {
    let conversations: [ChatConversationDTO]
}

struct ChatConversationDTO: Decodable {
    let messages: [ChatHistoryMessageDTO]
}

struct ChatHistoryMessageDTO: Decodable {
    let role: String
    let content: String
}
