import Foundation

import DomainInterface
import NetworkingInterface

import Dependencies

private actor AccessTokenStore {
    var value: String?
    private var refreshTask: Task<Bool, Never>?

    func set(_ token: String) { value = token }
    func clear() { value = nil }

    // 동시에 여러 곳에서 401을 받아도 refresh 시도는 하나만 진행되도록 묶는다.
    func refresh(_ operation: @escaping @Sendable () async -> Bool) async -> Bool {
        if let refreshTask {
            return await refreshTask.value
        }
        let task = Task { await operation() }
        refreshTask = task
        let result = await task.value
        refreshTask = nil
        return result
    }
}

extension AuthSessionRepository: DependencyKey {
    public static let liveValue: AuthSessionRepository = {
        let store = AccessTokenStore()
        let (stream, continuation) = AsyncStream<AuthState>.makeStream()
        return AuthSessionRepository(
            getAccessToken: { await store.value },
            setAccessToken: {
                await store.set($0)
                continuation.yield(.authenticated)
            },
            getRefreshToken: {
                @Dependency(\.authLocalDataSource) var local
                return try local.loadRefreshToken()
            },
            setRefreshToken: {
                @Dependency(\.authLocalDataSource) var local
                try local.saveRefreshToken($0)
            },
            clear: {
                @Dependency(\.authLocalDataSource) var local
                await store.clear()
                // yield 먼저 — keychain 삭제 실패 시에도 stream이 막히지 않도록
                continuation.yield(.unauthenticated)
                try local.deleteRefreshToken()
            },
            deleteAccount: {
                guard let token = await store.value else {
                    throw NetworkError.invalidRequest
                }
                @Dependency(\.authSessionRemoteDataSource) var remote
                @Dependency(\.authLocalDataSource) var local
                try await remote.deleteAccount(accessToken: token)
                await store.clear()
                continuation.yield(.unauthenticated)
                try local.deleteRefreshToken()
            },
            refreshAccessToken: {
                @Dependency(\.authSessionRemoteDataSource) var remote
                @Dependency(\.authLocalDataSource) var local

                return await store.refresh {
                    do {
                        let refreshToken = try local.loadRefreshToken()
                        let dto = try await remote.refreshToken(refreshToken)
                        let token = dto.toDomain()
                        await store.set(token.accessToken)
                        continuation.yield(.authenticated)
                        try local.saveRefreshToken(token.refreshToken)
                        return true
                    } catch {
                        await store.clear()
                        continuation.yield(.unauthenticated)
                        try? local.deleteRefreshToken()
                        return false
                    }
                }
            },
            stateStream: { stream }
        )
    }()
}
