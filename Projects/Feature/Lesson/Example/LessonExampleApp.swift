import SwiftUI

import FeatureSession

import Dependencies

@main
struct VocaExampleApp: App {
    init() {
        prepareDependencies {
            $0.getSessionDetailUseCase = .previewValue
        }
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                SessionDetailView(viewModel: SessionDetailViewModel(sessionID: "demo"))
            }
        }
    }
}
