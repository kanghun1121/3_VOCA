import Foundation

import DomainInterface

extension ChatMessagePayload {
    func toDomain() throws -> ChatHistory.Message {
        guard let parsedRole = ChatHistory.Message.Role(rawValue: role) else {
            throw ChatHistoryMappingError.invalidRole(role)
        }
        return ChatHistory.Message(id: id, role: parsedRole, content: content)
    }
}

extension ChatHistory.Message {
    var asPayload: ChatMessagePayload {
        ChatMessagePayload(id: id, role: role.rawValue, content: content)
    }
}
