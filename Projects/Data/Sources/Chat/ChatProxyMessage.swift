import Foundation

struct ChatProxyMessage: Sendable, Equatable, Codable {
    let role: String
    let content: String
}
