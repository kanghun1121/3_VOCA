import Foundation

import Dependencies

/// 인증 세션 상태(access/refresh token, 인증 상태 스트림)를 관리하는 포트. 실제 구현은 Data 모듈에서 제공한다.
public struct AuthSessionRepository: Sendable {
    public var getAccessToken: @Sendable () async -> String?
    public var setAccessToken: @Sendable (String) async -> Void
    public var getRefreshToken: @Sendable () throws -> String
    public var setRefreshToken: @Sendable (String) throws -> Void
    public var clear: @Sendable () async throws -> Void
    public var deleteAccount: @Sendable () async throws -> Void
    public var refreshAccessToken: @Sendable () async -> Bool
    public var stateStream: @Sendable () -> AsyncStream<AuthState>

    public init(
        getAccessToken: @escaping @Sendable () async -> String?,
        setAccessToken: @escaping @Sendable (String) async -> Void,
        getRefreshToken: @escaping @Sendable () throws -> String,
        setRefreshToken: @escaping @Sendable (String) throws -> Void,
        clear: @escaping @Sendable () async throws -> Void,
        deleteAccount: @escaping @Sendable () async throws -> Void,
        refreshAccessToken: @escaping @Sendable () async -> Bool,
        stateStream: @escaping @Sendable () -> AsyncStream<AuthState>
    ) {
        self.getAccessToken = getAccessToken
        self.setAccessToken = setAccessToken
        self.getRefreshToken = getRefreshToken
        self.setRefreshToken = setRefreshToken
        self.clear = clear
        self.deleteAccount = deleteAccount
        self.refreshAccessToken = refreshAccessToken
        self.stateStream = stateStream
    }
}

extension AuthSessionRepository: TestDependencyKey {
    public static let testValue = AuthSessionRepository(
        getAccessToken: unimplemented("\(Self.self).getAccessToken"),
        setAccessToken: unimplemented("\(Self.self).setAccessToken"),
        getRefreshToken: unimplemented("\(Self.self).getRefreshToken"),
        setRefreshToken: unimplemented("\(Self.self).setRefreshToken"),
        clear: unimplemented("\(Self.self).clear"),
        deleteAccount: unimplemented("\(Self.self).deleteAccount"),
        refreshAccessToken: unimplemented("\(Self.self).refreshAccessToken"),
        stateStream: unimplemented("\(Self.self).stateStream")
    )

    public static let previewValue = AuthSessionRepository(
        getAccessToken: { nil },
        setAccessToken: { _ in },
        getRefreshToken: { "" },
        setRefreshToken: { _ in },
        clear: {},
        deleteAccount: {},
        refreshAccessToken: { false },
        stateStream: { AsyncStream { $0.finish() } }
    )
}

public extension DependencyValues {
    var authSessionRepository: AuthSessionRepository {
        get { self[AuthSessionRepository.self] }
        set { self[AuthSessionRepository.self] = newValue }
    }
}
