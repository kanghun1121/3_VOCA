import Foundation

import DomainInterface

extension ChatMessagePayload {
    func toDomain() throws -> ChatHistory.Message {
        guard let parsedRole = ChatHistory.Message.Role(rawValue: role) else {
            throw ChatHistoryMappingError.invalidRole(role)
        }
        return ChatHistory.Message(role: parsedRole, content: content)
    }
}

extension ChatHistory.Message {
    var asPayload: ChatMessagePayload {
        ChatMessagePayload(role: role.rawValue, content: content)
    }
}
