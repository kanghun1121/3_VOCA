import Foundation

struct ChatProxyRequestBody: Encodable {
    let stream = true
    let messages: [ChatProxyMessage]
}
