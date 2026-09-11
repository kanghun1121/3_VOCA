import Foundation

import Dependencies

/// 챗봇 SSE 스트리밍의 sse_id/conversation_id 세션 상태(서브플랜 10) — 서버 프로토콜 디테일이라
/// Data 레이어 안에서만 알면 된다. `ChatBotViewModel`은 이 값들의 존재 자체를 모른다 — 정지
/// 프로토콜이 나중에 또 바뀌어도(예: 상관관계 식별자 방식 변경) `ChatRepository+Live`와 이
/// 파일만 바뀌고 ViewModel은 그대로다. `wordID`(화면 하나) 단위로 상태를 독립적으로 들고 있다.
actor ChatSessionStore {
    private struct Session {
        var conversationID: String?
        var activeSSEID: String?
    }

    private var sessions: [String: Session] = [:]

    /// 새 전송을 시작하며 이번 전송에 쓸 sse_id를 새로 발급하고 "진행 중"으로 기록한다.
    func beginSend(wordID: String) -> String {
        let sseID = UUID().uuidString
        sessions[wordID, default: Session()].activeSSEID = sseID
        return sseID
    }

    /// 진행 중이던 전송이 끝났다(성공/실패/취소 무관) — 더 이상 정지 대상이 아니다.
    func endSend(wordID: String) {
        sessions[wordID]?.activeSSEID = nil
    }

    /// 이 단어에 대해 마지막으로 저장된 대화 id — 같은 화면 방문의 두 번째 이후 전송에 재사용된다.
    func conversationID(for wordID: String) -> String? {
        sessions[wordID]?.conversationID
    }

    func setConversationID(_ conversationID: String, wordID: String) {
        sessions[wordID, default: Session()].conversationID = conversationID
    }

    /// 이 단어에 진행 중인 전송이 있다면 그 sse_id — 없으면 nil(정지 요청 대상이 없다는 뜻).
    func activeSSEID(for wordID: String) -> String? {
        sessions[wordID]?.activeSSEID
    }
}

extension ChatSessionStore: DependencyKey {
    static let liveValue = ChatSessionStore()
}

extension DependencyValues {
    var chatSessionStore: ChatSessionStore {
        get { self[ChatSessionStore.self] }
        set { self[ChatSessionStore.self] = newValue }
    }
}
