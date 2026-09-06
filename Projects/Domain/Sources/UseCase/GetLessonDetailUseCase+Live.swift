import Foundation

import DomainInterface

import Dependencies

extension GetSessionDetailUseCase: DependencyKey {
    public static let liveValue = GetSessionDetailUseCase(
        execute: { id in
            @Dependency(\.sessionRepository) var sessionRepository
            return try await sessionRepository.fetchSessionDetail(id)
        }
    )
}
