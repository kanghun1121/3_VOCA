import SwiftUI

import Data
import Domain
import DomainInterface

import Dependencies

@main
struct DomainExampleApp: App {
    init() {
        prepareDependencies {
            $0.lessonRepository = .liveValue
            $0.wordRepository = .liveValue
            $0.signInWithAppleUseCase = .liveValue
        }
    }

    var body: some Scene {
        WindowGroup {
            ClientListView()
        }
    }
}
