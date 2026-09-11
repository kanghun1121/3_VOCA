import Foundation

/// 챗봇 대화 히스토리 — 서버는 conversation 단위로 나눠 보내지만, 이 모델은 화면이 실제로
/// 쓰는 형태(단일하게 이어진 메시지 목록)를 그대로 반영한다. conversation 경계는 클라이언트
/// 어디에서도 쓰이지 않아 모델에 담지 않는다(평탄화는 `ChatHistoryResponseDTO+Mapping.swift`가
/// 담당). `wordID`도 담지 않는다 — 아무 소비자도 안 읽는 값이었고, 로컬 캐시 단독 조회
/// 시점에는 서버가 준 wordID 자체가 없어 채울 수 없었다(서브플랜 9).
public struct ChatHistory: Equatable, Sendable {
    public struct Message: Equatable, Sendable {
        public enum Role: String, Equatable, Sendable {
            case user
            case assistant
        }

        public let id: Int
        public let role: Role
        public let content: String

        public init(id: Int, role: Role, content: String) {
            self.id = id
            self.role = role
            self.content = content
        }
    }

    public let messages: [Message]

    public init(messages: [Message]) {
        self.messages = messages
    }
}
