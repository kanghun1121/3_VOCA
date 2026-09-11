import Foundation

import DomainInterface

enum ChatHistoryMappingError: Error, Equatable {
    case invalidRole(String)
}

extension ChatHistoryResponseDTO {
    /// 서버가 conversation 단위로 나눠 보낸 메시지를 여기서 평탄화한다 — Domain
    /// 모델(`ChatHistory`)이 이미 단일 메시지 목록만 가지므로, 평탄화는 이 매핑 지점 하나에서
    /// 끝난다(호출부에서 다시 flatMap할 필요 없음).
    func toDomain() throws -> ChatHistory {
        ChatHistory(messages: try conversations.flatMap(\.messages).map { try $0.toDomain() })
    }
}

extension ChatHistoryMessageDTO {
    func toDomain() throws -> ChatHistory.Message {
        guard let parsedRole = ChatHistory.Message.Role(rawValue: role) else {
            throw ChatHistoryMappingError.invalidRole(role)
        }
        return ChatHistory.Message(id: id, role: parsedRole, content: content)
    }
}
