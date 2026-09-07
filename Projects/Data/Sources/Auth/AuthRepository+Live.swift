import Foundation

import DomainInterface

import Dependencies

extension AuthRepository: DependencyKey {
    public static let liveValue = AuthRepository(
        signInWithApple: { identityToken in
            @Dependency(\.authRemoteDataSource) var remote
            let dto = try await remote.exchangeAppleToken(identityToken: identityToken)
            return dto.toDomain()
        }
    )
}
