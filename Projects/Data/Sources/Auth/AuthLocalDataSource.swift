import Foundation

import Core

import Dependencies

/// Keychain에 저장되는 refreshToken을 `.refreshToken` 키로 고정해 감싸는 얇은 계층. Auth
/// 도메인 코드가 `Core.KeychainKey`라는 세부사항을 직접 알 필요 없게 봉쇄하는 게 목적이다.
struct AuthLocalDataSource: Sendable {
    func loadRefreshToken() throws -> String {
        @Dependency(\.keychainClient) var keychain
        return try keychain.load(.refreshToken)
    }

    func saveRefreshToken(_ token: String) throws {
        @Dependency(\.keychainClient) var keychain
        try keychain.save(.refreshToken, token)
    }

    func deleteRefreshToken() throws {
        @Dependency(\.keychainClient) var keychain
        try keychain.delete(.refreshToken)
    }
}

extension AuthLocalDataSource: DependencyKey {
    static let liveValue = AuthLocalDataSource()
}

extension AuthLocalDataSource: TestDependencyKey {
    static let testValue = AuthLocalDataSource()
}

extension DependencyValues {
    var authLocalDataSource: AuthLocalDataSource {
        get { self[AuthLocalDataSource.self] }
        set { self[AuthLocalDataSource.self] = newValue }
    }
}
