import SwiftUI

import FeatureHome

@main
struct HomeExampleApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView(viewModel: HomeViewModel())
        }
    }
}
