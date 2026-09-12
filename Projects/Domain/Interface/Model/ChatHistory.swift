import Foundation

public struct ChatHistory: Equatable, Sendable {
    public struct Message: Equatable, Sendable {
        public enum Role: String, Equatable, Sendable {
            case user
            case assistant
        }

        public let role: Role
        public let content: String

        public init(role: Role, content: String) {
            self.role = role
            self.content = content
        }
    }

    public let messages: [Message]

    public init(messages: [Message]) {
        self.messages = messages
    }
}
