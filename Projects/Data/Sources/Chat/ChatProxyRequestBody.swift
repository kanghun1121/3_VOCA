import Foundation

struct ChatProxyRequestBody: Encodable {
    let model: String
    let maxTokens: Int
    let stream = true
    let messages: [ChatProxyMessage]

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case stream
        case messages
    }
}
