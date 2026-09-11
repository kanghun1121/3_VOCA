import Foundation

import NetworkingInterface

public struct SSEClient: SSEClienting {
    private let session: URLSession
    private let frameReader: any SSEFraming

    public init(session: URLSession = .shared) {
        self.init(session: session, frameReader: SSEFrameReader())
    }

    /// 테스트에서 가짜 프레임 리더를 주입하기 위한 초기화. `SSEFraming` 구현은 값 타입이라
    /// `stream(_:)`에서 `var reader = frameReader`로 대입(복사)하기만 해도 호출마다 독립된 상태가
    /// 보장된다 — copy-on-write 값 의미론.
    init(session: URLSession = .shared, frameReader: any SSEFraming) {
        self.session = session
        self.frameReader = frameReader
    }

    public func stream(
        _ requestable: any Requestable,
        onResponse: (@Sendable (HTTPURLResponse) -> Void)?
    ) -> AsyncThrowingStream<SSEFrame, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                let logger = NetworkLogger()
                do {
                    let request = try requestable.makeURLRequest()
                    logger.logRequest(request)

                    let (bytes, response) = try await session.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: NetworkError.invalidResponse)
                        return
                    }

                    guard (200..<300).contains(httpResponse.statusCode) else {
                        // 스트리밍이 시작되기 전 실패 — 일반 JSON 에러 바디이므로 모아서 담는다.
                        var errorBody = Data()
                        for try await line in bytes.lines {
                            errorBody.append(Data(line.utf8))
                        }
                        continuation.finish(
                            throwing: NetworkError.httpError(statusCode: httpResponse.statusCode, data: errorBody)
                        )
                        return
                    }

                    onResponse?(httpResponse)

                    var reader = frameReader

                    for try await line in bytes.lines {
                        let frame = reader.feed(line)
                        guard !frame.data.isEmpty else { continue }
                        continuation.yield(frame)
                    }

                    let finalFrame = reader.flush()
                    if !finalFrame.data.isEmpty {
                        continuation.yield(finalFrame)
                    }

                    continuation.finish()
                } catch {
                    logger.logError(error, context: "SSEClient")
                    continuation.finish(throwing: NetworkError.requestFailed(error))
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
