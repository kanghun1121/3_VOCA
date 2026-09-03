import SwiftUI

import FeatureHome

import Dependencies

@main
struct HomeExampleApp: App {
    init() {
        prepareDependencies {
            $0.vocabularyLibraryRepository = .previewValue
        }
    }

    var body: some Scene {
        WindowGroup {
            HomeView(viewModel: HomeViewModel())
        }
    }
}
