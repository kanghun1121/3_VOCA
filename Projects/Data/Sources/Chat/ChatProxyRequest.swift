import Foundation

import NetworkingInterface

/// requiresAuthentication은 이 요청이 HTTPClient의 인터셉터 파이프라인(TokenRefreshInterceptor)을
/// 타지 않는다는 의도를 명시하기 위해 false로 남겨둔다 — SSEClient가 session.bytes(for:)로 직접
/// 요청하기 때문이다. 대신 SSEClienting의 설계 의도대로 accessToken을 headers에 직접 실어 보낸다.
struct ChatProxyRequest: Requestable {
    let messages: [ChatProxyMessage]
    let sseID: String
    let wordID: String?
    let conversationID: String?
    let accessToken: String?

    init(
        messages: [ChatProxyMessage],
        sseID: String,
        wordID: String? = nil,
        conversationID: String? = nil,
        accessToken: String? = nil
    ) {
        self.messages = messages
        self.sseID = sseID
        self.wordID = wordID
        self.conversationID = conversationID
        self.accessToken = accessToken
    }

    var baseURL: URL { SupabaseConfig.baseURL }
    var path: String { "functions/v1/chat" }
    var method: HTTPMethod { .post }
    var bodyParameters: HTTPBody {
        .json(ChatProxyRequestBody(
            messages: messages,
            sseID: sseID,
            wordID: wordID,
            conversationID: conversationID
        ))
    }
    var requiresAuthentication: Bool { false }

    var headers: [String: String] {
        guard let accessToken else { return [:] }
        return ["Authorization": "Bearer \(accessToken)"]
    }
}
