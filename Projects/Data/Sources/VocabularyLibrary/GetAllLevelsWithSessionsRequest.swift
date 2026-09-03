import Foundation

import NetworkingInterface

struct GetAllLevelsWithSessionsRequest: Requestable {
    var baseURL: URL { SupabaseConfig.baseURL }
    var path: String { "/rest/v1/rpc/get_all_levels_with_sessions" }
    var method: HTTPMethod { .post }
    var bodyParameters: HTTPBody { .json(EmptyParams()) }
    var headers: [String: String] {
        [
            "apikey": SupabaseConfig.anonKey,
            "Accept": "application/json"
        ]
    }
}

private struct EmptyParams: Encodable {}
