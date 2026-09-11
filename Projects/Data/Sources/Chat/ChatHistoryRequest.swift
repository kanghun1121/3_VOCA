import Foundation

import NetworkingInterface

/// requiresAuthentication은 기본값(true)을 그대로 쓴다 — POST(SSE)와 달리 이 요청은 일반
/// GET/JSON이라 HTTPClient를 통해 보내고, TokenRefreshInterceptor가 Authorization 헤더를
/// 자동으로 붙여준다.
///
/// wordID는 WordDetail.id와 같은 문자열 형식(예: "word_766")을 그대로 받는다 — 서버가 이
/// 형식을 그대로 받아들이도록 바뀌어서, 클라이언트가 별도로 정수로 변환할 필요가 없다.
struct ChatHistoryRequest: Requestable {
    let wordID: String

    var baseURL: URL { SupabaseConfig.baseURL }
    var path: String { "functions/v1/chat" }
    var method: HTTPMethod { .get }
    var queryParameters: (any Encodable)? { ChatHistoryQuery(wordID: wordID) }
}

private struct ChatHistoryQuery: Encodable {
    let wordID: String

    enum CodingKeys: String, CodingKey {
        case wordID = "word_id"
    }
}
