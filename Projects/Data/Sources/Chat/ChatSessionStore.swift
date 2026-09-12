import Foundation

import Dependencies

actor ChatSessionStore {
    private struct Session {
        var conversationID: String?
        var activeSSEID: String?
    }

    private var sessions: [String: Session] = [:]

    func beginSend(wordID: String) -> String {
        let sseID = UUID().uuidString
        sessions[wordID, default: Session()].activeSSEID = sseID
        return sseID
    }

    func endSend(wordID: String) {
        sessions[wordID]?.activeSSEID = nil
    }

    func conversationID(for wordID: String) -> String? {
        sessions[wordID]?.conversationID
    }

    func setConversationID(_ conversationID: String, wordID: String) {
        sessions[wordID, default: Session()].conversationID = conversationID
    }

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
