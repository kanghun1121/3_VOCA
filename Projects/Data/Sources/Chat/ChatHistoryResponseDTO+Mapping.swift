import Foundation

import DomainInterface

enum ChatHistoryMappingError: Error, Equatable {
    case invalidRole(String)
}

extension ChatHistoryResponseDTO {
    func toDomain() throws -> ChatHistory {
        ChatHistory(messages: try conversations.flatMap(\.messages).map { try $0.toDomain() })
    }
}

extension ChatHistoryMessageDTO {
    func toDomain() throws -> ChatHistory.Message {
        guard let parsedRole = ChatHistory.Message.Role(rawValue: role) else {
            throw ChatHistoryMappingError.invalidRole(role)
        }
        return ChatHistory.Message(role: parsedRole, content: content)
    }
}
