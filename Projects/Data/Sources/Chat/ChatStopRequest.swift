import Foundation

import NetworkingInterface

/// 진행 중인 SSE 전송을 "정지"시키는 요청 — `ChatHistoryRequest`와 동일하게 일반 POST/JSON이라
/// `authenticatedHTTPClient`(TokenRefreshInterceptor)를 그대로 탄다. 응답 `{"ok": true}`는
/// idempotent 성공 여부만 의미가 있어(상태 코드로 충분) 별도 Decodable로 모델링하지 않고
/// `HTTPClienting.request(_:) async throws`(void 오버로드)로 본문을 버린다.
struct ChatStopRequest: Requestable {
    let sseID: String

    var baseURL: URL { SupabaseConfig.baseURL }
    var path: String { "functions/v1/chat-stop" }
    var method: HTTPMethod { .post }
    var bodyParameters: HTTPBody { .json(Body(sseID: sseID)) }

    private struct Body: Encodable {
        let sseID: String

        enum CodingKeys: String, CodingKey {
            case sseID = "sse_id"
        }
    }
}
