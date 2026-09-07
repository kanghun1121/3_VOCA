import Foundation

import DomainInterface

import Dependencies

extension AuthRepository: DependencyKey {
    public static let liveValue = AuthRepository(
        signInWithApple: { identityToken in
            @Dependency(\.authRemoteDataSource) var remoteDataSource
            let dto = try await remoteDataSource.exchangeAppleToken(identityToken: identityToken)
            return dto.toDomain()
        }
    )
}
