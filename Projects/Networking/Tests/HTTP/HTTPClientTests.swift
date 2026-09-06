//
//  HTTPClientTests.swift
//  NetworkTests
//
//  Created by 강대훈 on 7/6/26.
//  Copyright © 2026 FiveVoca. All rights reserved.
//

import XCTest

import NetworkingInterface

@testable import Networking

final class HTTPClientTests: XCTestCase {
    override func tearDownWithError() throws {
        MockURLProtocol.requestHandler = nil
    }

    func test_request_200응답이면_snakeCase를_변환하여_디코딩한다() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = Data(#"{"some_value":"hello"}"#.utf8)
            return (response, data)
        }

        let sut = HTTPClient(session: MockURLProtocol.makeSession())
        let result: StubDecodable = try await sut.request(StubRequestable())

        XCTAssertEqual(result.someValue, "hello")
    }

    func test_request_2xx가_아니면_httpError를_던진다() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 404,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let sut = HTTPClient(session: MockURLProtocol.makeSession())

        do {
            let _: StubDecodable = try await sut.request(StubRequestable())
            XCTFail("NetworkError.httpError가 던져져야 합니다.")
        } catch NetworkError.httpError(let statusCode, _) {
            XCTAssertEqual(statusCode, 404)
        } catch {
            XCTFail("NetworkError.httpError가 아닌 다른 에러입니다: \(error)")
        }
    }

    func test_request_401응답에서_retry가_true를_반환하면_재요청하여_성공응답을_반환한다() async throws {
        let interceptor = SpyHTTPInterceptor()
        interceptor.shouldRetry = true

        MockURLProtocol.requestHandler = { request in
            if interceptor.retryCallCount == 0 {
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 401,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (response, Data())
            } else {
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
                let data = Data(#"{"some_value":"retried"}"#.utf8)
                return (response, data)
            }
        }
        let sut = HTTPClient(interceptor: interceptor, session: MockURLProtocol.makeSession())

        let result: StubDecodable = try await sut.request(StubRequestable())

        XCTAssertEqual(result.someValue, "retried")
        XCTAssertEqual(interceptor.retryCallCount, 1)
    }

    func test_request_401응답에서_retry가_false를_반환하면_재요청없이_httpError를_던진다() async {
        let interceptor = SpyHTTPInterceptor()
        interceptor.shouldRetry = false

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }
        let sut = HTTPClient(interceptor: interceptor, session: MockURLProtocol.makeSession())

        do {
            let _: StubDecodable = try await sut.request(StubRequestable())
            XCTFail("NetworkError.httpError가 던져져야 합니다.")
        } catch NetworkError.httpError(let statusCode, _) {
            XCTAssertEqual(statusCode, 401)
        } catch {
            XCTFail("NetworkError.httpError가 아닌 다른 에러입니다: \(error)")
        }

        XCTAssertEqual(interceptor.retryCallCount, 1)
    }

    func test_request_requiresAuthentication이_true이면_adapt가_호출되어_요청이_변형된다() async throws {
        let interceptor = SpyHTTPInterceptor()

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = Data(#"{"some_value":"ok"}"#.utf8)
            return (response, data)
        }
        let sut = HTTPClient(interceptor: interceptor, session: MockURLProtocol.makeSession())

        _ = try await sut.request(StubRequestable(requiresAuthentication: true)) as StubDecodable

        XCTAssertEqual(interceptor.adaptCallCount, 1)
        XCTAssertEqual(interceptor.lastAdaptedRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer stub-token")
    }

    func test_request_requiresAuthentication이_false이면_adapt가_호출되지_않는다() async throws {
        let interceptor = SpyHTTPInterceptor()

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = Data(#"{"some_value":"ok"}"#.utf8)
            return (response, data)
        }
        let sut = HTTPClient(interceptor: interceptor, session: MockURLProtocol.makeSession())

        _ = try await sut.request(StubRequestable(requiresAuthentication: false)) as StubDecodable

        XCTAssertEqual(interceptor.adaptCallCount, 0)
    }

    func test_data_200이면_원본_바이트를_그대로_반환한다() async throws {
        let expected = Data([0x01, 0x02, 0x03])
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, expected)
        }
        let sut = HTTPClient(session: MockURLProtocol.makeSession())

        let result = try await sut.data(from: URL(string: "https://example.com/audio.mp3?token=abc")!)

        XCTAssertEqual(result, expected)
    }

    func test_data_전달한_절대_URL을_쿼리스트링_포함_원형_그대로_GET으로_요청한다() async throws {
        let requestedURL = URL(string: "https://example.com/audio/word.mp3?token=abc")!
        let capture = RequestCapture()
        MockURLProtocol.requestHandler = { request in
            capture.request = request
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }
        let sut = HTTPClient(session: MockURLProtocol.makeSession())

        _ = try await sut.data(from: requestedURL)

        XCTAssertEqual(capture.request?.url, requestedURL)
        XCTAssertEqual(capture.request?.httpMethod, "GET")
    }

    func test_data_2xx가_아니면_httpError를_던진다() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 404,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }
        let sut = HTTPClient(session: MockURLProtocol.makeSession())

        do {
            _ = try await sut.data(from: URL(string: "https://example.com/missing.mp3")!)
            XCTFail("NetworkError.httpError가 던져져야 합니다.")
        } catch NetworkError.httpError(let statusCode, _) {
            XCTAssertEqual(statusCode, 404)
        } catch {
            XCTFail("NetworkError.httpError가 아닌 다른 에러입니다: \(error)")
        }
    }

    func test_data_전송_실패시_requestFailed로_감싸서_던진다() async {
        struct StubTransportError: Error {}
        MockURLProtocol.requestHandler = { _ in
            throw StubTransportError()
        }
        let sut = HTTPClient(session: MockURLProtocol.makeSession())

        do {
            _ = try await sut.data(from: URL(string: "https://example.com/audio.mp3")!)
            XCTFail("NetworkError.requestFailed가 던져져야 합니다.")
        } catch NetworkError.requestFailed {
            // 기대한 경로
        } catch {
            XCTFail("NetworkError.requestFailed가 아닌 다른 에러입니다: \(error)")
        }
    }
}

private struct StubDecodable: Decodable, Equatable {
    let someValue: String
}

/// 클로저에서 캡처한 요청을 기록하는 테스트 더블. `var` 지역변수를 클로저 안에서 직접
/// 캡처·변경하면 Swift 6에서 "concurrently-executing code" 경고가 발생하므로, 다른
/// 스파이 더블(`SpyHTTPInterceptor`)과 동일하게 참조 타입으로 감싼다.
private final class RequestCapture: @unchecked Sendable {
    var request: URLRequest?
}
