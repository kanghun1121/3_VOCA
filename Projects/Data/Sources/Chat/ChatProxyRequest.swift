import Foundation

import NetworkingInterface

/// requiresAuthentication은 이 요청이 HTTPClient의 인터셉터 파이프라인을 타지 않고
/// (SSEClient가 session.bytes(for:)로 직접 요청하므로) 별도 인증 헤더도 없다는 의도를
/// 명시하기 위해 false로 남겨둔다.
struct ChatProxyRequest: Requestable {
    let messages: [ChatProxyMessage]

    var baseURL: URL { SupabaseConfig.baseURL }
    var path: String { "functions/v1/chat" }
    var method: HTTPMethod { .post }
    var bodyParameters: HTTPBody { .json(ChatProxyRequestBody(messages: messages)) }
    var requiresAuthentication: Bool { false }
}
