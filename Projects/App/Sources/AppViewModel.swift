import SwiftUI

import Data
import DomainInterface

import Dependencies

@Observable
@MainActor
final class AppViewModel {
    var isSeedingDatabase = true

    @ObservationIgnored @Dependency(\.refreshAuthSessionUseCase) private var refreshAuthSessionUseCase
    @ObservationIgnored @Dependency(\.localDatabaseSeeding) private var localDatabaseSeeding

    func onAppear() {
        // 화면 분기와 무관한 선제적 토큰 갱신 — 로그인 상태였던 사용자의 첫 인증 요청이
        // 무토큰으로 나갔다가 401을 받고서야 갱신되는 왕복을 줄인다.
        Task { [weak self] in
            guard let self else { return }
            await refreshAuthSessionUseCase.execute()
        }

        Task { [weak self] in
            guard let self else { return }
            try? await localDatabaseSeeding.seedIfNeeded()
            isSeedingDatabase = false
        }
    }
}
