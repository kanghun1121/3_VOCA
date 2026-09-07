import SwiftUI

import Data
import DomainInterface

import Dependencies

@Observable
@MainActor
final class AppViewModel {
    var authState: AuthState = .unauthenticated
    var isCheckingSession = true
    var isSeedingDatabase = true

    @ObservationIgnored @Dependency(\.checkAuthSessionUseCase) private var checkAuthSessionUseCase
    @ObservationIgnored @Dependency(\.authSessionRepository) private var authSessionRepository
    @ObservationIgnored @Dependency(\.refreshAuthSessionUseCase) private var refreshAuthSessionUseCase
    @ObservationIgnored @Dependency(\.localDatabaseSeeding) private var localDatabaseSeeding

    private var streamTask: Task<Void, Never>?

    init() {
        authState = checkAuthSessionUseCase.execute() ? .authenticated : .unauthenticated
    }

    func onAppear() {
        guard streamTask == nil else { return }
        streamTask = Task { [weak self] in
            guard let self else { return }
            for await state in authSessionRepository.stateStream() {
                authState = state
            }
        }

        Task { [weak self] in
            guard let self else { return }
            await refreshAuthSessionUseCase.execute()
            isCheckingSession = false
        }

        Task { [weak self] in
            guard let self else { return }
            try? await localDatabaseSeeding.seedIfNeeded()
            isSeedingDatabase = false
        }
    }
}
