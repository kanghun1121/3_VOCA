import Foundation

import DomainInterface

import Dependencies

extension CompleteSessionUseCase: DependencyKey {
    public static let liveValue = CompleteSessionUseCase(
        execute: { sessionID in
            @Dependency(\.sessionRepository) var sessionRepository
            try await sessionRepository.completeSession(sessionID)
        }
    )
}
