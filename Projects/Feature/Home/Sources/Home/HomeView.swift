import SwiftUI

import DesignSystem
import FeatureLesson

import SwiftUINavigation

public struct HomeView: View {
    @State private var viewModel: HomeViewModel

    public init(viewModel: HomeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            HomeContentView(viewModel: viewModel)
                .task { await viewModel.onAppear() }
                .navigationDestination(item: $viewModel.destination.lesson) { detailVM in
                    LessonDetailView(viewModel: detailVM)
                }
                .navigationDestination(item: $viewModel.destination.learningLibrary) { libraryVM in
                    LearningLibraryView(viewModel: libraryVM)
                }
        }
        .tint(DesignSystemAsset.fgStrong.swiftUIColor)
        .toolbar(viewModel.destination != nil ? .hidden : .visible, for: .tabBar)
    }
}

#Preview("홈") {
    HomeView(viewModel: HomeViewModel())
}
