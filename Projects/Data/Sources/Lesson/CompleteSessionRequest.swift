import Foundation

import NetworkingInterface

struct CompleteSessionRequest: Requestable {
    let sessionID: Int
    let localDate: String

    var baseURL: URL { SupabaseConfig.baseURL }
    var path: String { "/rest/v1/rpc/complete_session" }
    var method: HTTPMethod { .post }
    var bodyParameters: HTTPBody { .json(Params(pSessionId: sessionID, pDate: localDate)) }
    var headers: [String: String] {
        [
            "apikey": SupabaseConfig.anonKey,
            "Accept": "application/json"
        ]
    }
}

private struct Params: Encodable {
    let pSessionId: Int
    let pDate: String

    enum CodingKeys: String, CodingKey {
        case pSessionId = "p_session_id"
        case pDate = "p_date"
    }
}

struct CompleteSessionResponseDTO: Decodable {
    let success: Bool
}
