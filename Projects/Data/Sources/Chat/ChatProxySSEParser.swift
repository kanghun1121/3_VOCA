import Foundation

import NetworkingInterface

/// SSE 프레임 시퀀스를 Claude Messages API 이벤트 스키마에 맞춰 ChatProxyStreamEvent로
/// 매핑한다. 프레임 분리(빈 줄 기준 event/data 파싱)는 SSEClient(Networking)가 이미 끝낸 뒤 넘겨준다
/// — 이 타입은 순수하게 (프록시가 그대로 전달하는) Claude 이벤트 스키마 해석만 담당한다. 완료 조건 분석:
/// - `content_block_delta`(text_delta) → `.textDelta`로 방출, 스트림은 계속된다.
/// - `message_stop` → `.messageStop`을 방출한 뒤 스트림을 finish()로 정상 종료한다(더 이상 프레임을 읽지 않는다).
/// - `message_start`/`content_block_start`/`ping`/`content_block_stop`/`message_delta` → 무시하고 계속한다.
/// - `event: error` 프레임(JSON type == "error") → NetworkError.streamError로 finish(throwing:).
/// - `data:` JSON 디코딩 실패 → NetworkError.decodingFailed로 finish(throwing:).
/// - message_stop 없이 프레임 시퀀스가 그냥 끝나면(EOF) 에러 없이 finish() — 서버 조기 종료를
///   클라이언트 크래시로 다루지 않기 위한 의도적 설계.
enum ChatProxySSEParser {
    static func parse<Frames: AsyncSequence>(
        frames: Frames
    ) -> AsyncThrowingStream<ChatProxyStreamEvent, Error> where Frames.Element == SSEFrame {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    for try await frame in frames {
                        if handle(frame, continuation) { return }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// 프레임 하나를 처리한다. 스트림을 끝내야 하면(message_stop/에러) true를 반환한다.
    private static func handle(
        _ frame: SSEFrame,
        _ continuation: AsyncThrowingStream<ChatProxyStreamEvent, Error>.Continuation
    ) -> Bool {
        guard let data = frame.data.data(using: .utf8) else { return false }

        let response: StreamTypeResponse
        do {
            response = try JSONDecoder().decode(StreamTypeResponse.self, from: data)
        } catch {
            continuation.finish(throwing: NetworkError.decodingFailed(error))
            return true
        }

        switch response.type {
        case "content_block_delta":
            if let delta = try? JSONDecoder().decode(ContentBlockDeltaResponse.self, from: data),
               delta.delta.type == "text_delta",
               let text = delta.delta.text {
                continuation.yield(.textDelta(text))
            }
            return false
        case "message_stop":
            continuation.yield(.messageStop)
            continuation.finish()
            return true
        case "error":
            let message = (try? JSONDecoder().decode(ErrorResponse.self, from: data))?.error.message
                ?? "unknown stream error"
            continuation.finish(throwing: NetworkError.streamError(message: message))
            return true
        default:
            return false
        }
    }

    /// SSE 프레임의 data: JSON에서 type 판별자만 우선 디코딩하기 위한 응답 타입.
    private struct StreamTypeResponse: Decodable {
        let type: String
    }

    private struct ContentBlockDeltaResponse: Decodable {
        struct Delta: Decodable {
            let type: String
            let text: String?
        }
        let delta: Delta
    }

    private struct ErrorResponse: Decodable {
        struct ErrorDetail: Decodable {
            let message: String
        }
        let error: ErrorDetail
    }
}
