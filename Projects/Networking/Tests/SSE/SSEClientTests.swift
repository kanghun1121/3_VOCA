import XCTest

import NetworkingInterface

@testable import Networking

final class SSEClientTests: XCTestCase {
    override func tearDownWithError() throws {
        MockURLProtocol.requestHandler = nil
    }

    func test_비2xx_응답이면_httpError로_종료된다() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (response, Data(#"{"error":{"message":"invalid api key"}}"#.utf8))
        }

        let sut = SSEClient(session: MockURLProtocol.makeSession())

        do {
            _ = try await collect(sut.stream(StubRequestable()))
            XCTFail("NetworkError.httpError가 던져져야 합니다.")
        } catch NetworkError.httpError(let statusCode, _) {
            XCTAssertEqual(statusCode, 401)
        } catch {
            XCTFail("NetworkError.httpError가 아닌 다른 에러입니다: \(error)")
        }
    }

    /// 프레임 리더를 주입받아 실제 SSE 텍스트 파싱 없이 SSEClient의 오케스트레이션만 검증한다:
    /// feed()의 빈 프레임은 스킵되고(StubSSEFraming.feedResult가 항상 빈 프레임), EOF에서
    /// flush()가 반환한 프레임은 스트림 끝에 방출된다.
    func test_feed의_빈_프레임은_스킵되고_flush_결과는_방출된다() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data("x\n".utf8))
        }

        let flushedFrame = SSEFrame(event: "done", data: "trailing")
        let sut = SSEClient(
            session: MockURLProtocol.makeSession(),
            frameReader: StubSSEFraming(feedResult: SSEFrame(event: nil, data: ""), flushResult: flushedFrame)
        )

        let frames = try await collect(sut.stream(StubRequestable()))

        XCTAssertEqual(frames, [flushedFrame])
    }

    /// `onResponse`는 상태 코드 검증을 통과한 직후, 프레임을 읽기 전에 딱 1번 호출돼야 한다 —
    /// `x-conversation-id`처럼 헤더로만 오는 값을 소비자가 읽을 수 있게 하는 사이드 채널이다.
    func test_onResponse는_상태코드_검증_통과_후_헤더와_함께_한_번_호출된다() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["x-conversation-id": "conv-001"]
            )!
            return (response, Data("x\n".utf8))
        }

        let sut = SSEClient(
            session: MockURLProtocol.makeSession(),
            frameReader: StubSSEFraming(feedResult: SSEFrame(event: nil, data: ""), flushResult: SSEFrame(event: nil, data: ""))
        )

        let spy = OnResponseSpy()
        _ = try await collect(sut.stream(StubRequestable()) { response in
            spy.receivedHeaders.append(response.value(forHTTPHeaderField: "x-conversation-id"))
        })

        XCTAssertEqual(spy.receivedHeaders, ["conv-001"])
    }

    /// 비2xx 응답은 프레임 읽기 전에 에러로 끝나므로, `onResponse`는 호출되면 안 된다.
    func test_비2xx_응답이면_onResponse가_호출되지_않는다() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        let sut = SSEClient(session: MockURLProtocol.makeSession())

        let spy = OnResponseSpy()
        _ = try? await collect(sut.stream(StubRequestable()) { _ in
            spy.callCount += 1
        })

        XCTAssertEqual(spy.callCount, 0)
    }
}

/// `onResponse` 콜백이 SSEClient 내부 Task(별도 실행 컨텍스트)에서 호출되므로, 로컬 `var` 캡처는
/// Swift 6 동시성 검사에 걸린다 — `SpyHTTPInterceptor`와 동일한 패턴(`@unchecked Sendable` 스파이
/// 클래스)으로 기록한다. 테스트는 스트림을 끝까지 `await`한 뒤에만 값을 읽으므로 실제 동시
/// 접근은 없다.
private final class OnResponseSpy: @unchecked Sendable {
    var receivedHeaders: [String?] = []
    var callCount = 0
}

private func collect<S: AsyncSequence>(_ sequence: S) async throws -> [S.Element] {
    var result: [S.Element] = []
    for try await element in sequence {
        result.append(element)
    }
    return result
}
