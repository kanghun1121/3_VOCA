import SwiftUI

import DomainInterface

import Dependencies

@Observable
@MainActor
final class AppViewModel {
    var authState: AuthState = .unauthenticated
    var isCheckingSession = true

    @ObservationIgnored @Dependency(\.checkAuthSessionUseCase) private var checkAuthSessionUseCase
    @ObservationIgnored @Dependency(\.authSessionRepository) private var authSessionRepository
    @ObservationIgnored @Dependency(\.refreshAuthSessionUseCase) private var refreshAuthSessionUseCase

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
    }
}
