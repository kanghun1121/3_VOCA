import Foundation

import NetworkingInterface

import Dependencies

/// 로그인된 세션의 갱신/삭제만 담당(로그인 자체는 `AuthRemoteDataSource`).
struct AuthSessionRemoteDataSource: Sendable {
    func refreshToken(_ refreshToken: String) async throws -> AuthTokenResponseDTO {
        @Dependency(\.httpClient) var httpClient
        return try await httpClient.request(RefreshTokenRequest(refreshToken: refreshToken))
    }

    func deleteAccount(accessToken: String) async throws {
        @Dependency(\.httpClient) var httpClient
        try await httpClient.request(DeleteAccountRequest(accessToken: accessToken))
    }
}

extension AuthSessionRemoteDataSource: DependencyKey {
    static let liveValue = AuthSessionRemoteDataSource()
}

extension AuthSessionRemoteDataSource: TestDependencyKey {
    static let testValue = AuthSessionRemoteDataSource()
}

extension DependencyValues {
    var authSessionRemoteDataSource: AuthSessionRemoteDataSource {
        get { self[AuthSessionRemoteDataSource.self] }
        set { self[AuthSessionRemoteDataSource.self] = newValue }
    }
}
