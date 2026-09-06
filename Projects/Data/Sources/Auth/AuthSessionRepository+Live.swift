import Foundation

import Core
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
        @Dependency(\.keychainClient) var keychain
        let (stream, continuation) = AsyncStream<AuthState>.makeStream()
        return AuthSessionRepository(
            getAccessToken: { await store.value },
            setAccessToken: {
                await store.set($0)
                continuation.yield(.authenticated)
            },
            getRefreshToken: { try keychain.load(.refreshToken) },
            setRefreshToken: { try keychain.save(.refreshToken, $0) },
            clear: {
                await store.clear()
                // yield 먼저 — keychain.delete 실패 시에도 stream이 막히지 않도록
                continuation.yield(.unauthenticated)
                try keychain.delete(.refreshToken)
            },
            deleteAccount: {
                guard let token = await store.value else {
                    throw NetworkError.invalidRequest
                }
                @Dependency(\.httpClient) var httpClient
                try await httpClient.request(DeleteAccountRequest(accessToken: token))
                await store.clear()
                continuation.yield(.unauthenticated)
                try keychain.delete(.refreshToken)
            },
            refreshAccessToken: {
                @Dependency(\.httpClient) var httpClient

                return await store.refresh {
                    do {
                        let refreshToken = try keychain.load(.refreshToken)
                        let request = RefreshTokenRequest(refreshToken: refreshToken)
                        let dto: AuthTokenResponseDTO = try await httpClient.request(request)
                        let token = dto.toDomain()
                        await store.set(token.accessToken)
                        continuation.yield(.authenticated)
                        try keychain.save(.refreshToken, token.refreshToken)
                        return true
                    } catch {
                        await store.clear()
                        continuation.yield(.unauthenticated)
                        try? keychain.delete(.refreshToken)
                        return false
                    }
                }
            },
            stateStream: { stream }
        )
    }()
}
