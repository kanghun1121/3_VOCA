import Foundation

import Dependencies

/// TokenRefreshInterceptor가 적용된 인증 클라이언트. 인증이 필요한 대부분의 요청에 사용한다.
/// (재귀 위험이 있는 refreshAccessToken/deleteAccount 등 소수 호출은 `httpClient`(Noop)를 그대로 쓴다.)
public extension DependencyValues {
    var authenticatedHTTPClient: any HTTPClienting {
        get { self[AuthenticatedHTTPClientKey.self] }
        set { self[AuthenticatedHTTPClientKey.self] = newValue }
    }
}

public enum AuthenticatedHTTPClientKey: TestDependencyKey {
    public static let testValue: any HTTPClienting = unimplemented(
        "\(Self.self).testValue",
        placeholder: NoopAuthenticatedHTTPClient()
    )
}

private struct NoopAuthenticatedHTTPClient: HTTPClienting {
    func request<T: Decodable>(_ requestable: any Requestable) async throws -> T {
        throw NetworkError.invalidRequest
    }

    func request(_ requestable: any Requestable) async throws {
        throw NetworkError.invalidRequest
    }

    func data(from url: URL) async throws -> Data {
        throw NetworkError.invalidRequest
    }
}
