import Foundation

import NetworkingInterface

struct GetSessionDetailRequest: Requestable {
    let sessionID: String

    var baseURL: URL { SupabaseConfig.baseURL }
    var path: String { "/rest/v1/rpc/get_session_detail" }
    var method: HTTPMethod { .post }
    var bodyParameters: HTTPBody { .json(Params(pSessionId: sessionID)) }
    var headers: [String: String] {
        [
            "apikey": SupabaseConfig.anonKey,
            "Accept": "application/json"
        ]
    }
}

private struct Params: Encodable {
    let pSessionId: String

    enum CodingKeys: String, CodingKey {
        case pSessionId = "p_session_id"
    }
}
