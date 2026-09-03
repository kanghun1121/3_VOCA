import SwiftUI

import Domain
import DomainInterface

import Dependencies

@main
struct DomainExampleApp: App {
    init() {
        prepareDependencies {
            $0.getSessionDetailUseCase = .liveValue
            $0.completeSessionUseCase = .liveValue
            $0.getWordDetailUseCase = .liveValue
            $0.prefetchWordDetailsUseCase = .liveValue
            $0.signInWithAppleUseCase = .liveValue
        }
    }

    var body: some Scene {
        WindowGroup {
            ClientListView()
        }
    }
}
