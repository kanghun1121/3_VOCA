import Foundation

import NetworkingInterface

import Dependencies

/// Apple 로그인 교환 요청. 회원가입/로그인 자체(계정 생성)만 담당 — 세션 갱신/삭제는
/// `AuthSessionRemoteDataSource`의 책임이다(별개 도메인 흐름이라 나눔).
struct AuthRemoteDataSource: Sendable {
    func exchangeAppleToken(identityToken: String) async throws -> AuthTokenResponseDTO {
        @Dependency(\.authenticatedHTTPClient) var client
        return try await client.request(ExchangeAppleTokenRequest(identityToken: identityToken))
    }
}

extension AuthRemoteDataSource: DependencyKey {
    static let liveValue = AuthRemoteDataSource()
}

extension AuthRemoteDataSource: TestDependencyKey {
    static let testValue = AuthRemoteDataSource()
}

extension DependencyValues {
    var authRemoteDataSource: AuthRemoteDataSource {
        get { self[AuthRemoteDataSource.self] }
        set { self[AuthRemoteDataSource.self] = newValue }
    }
}
