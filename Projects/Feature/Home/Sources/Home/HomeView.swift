import SwiftUI

import DesignSystem
import FeatureSession

import SwiftUINavigation

public struct HomeView: View {
    @State private var viewModel: HomeViewModel

    public init(viewModel: HomeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            Group {
                switch viewModel.uiState {
                case .loading:
                    HomeLoadingView()
                case .success(let library):
                    HomeContentView(state: library, viewModel: viewModel)
                case .error(let message):
                    ContentUnavailableView(message, systemImage: "exclamationmark.triangle")
                case .empty:
                    HomeEmptyView()
                }
            }
            .animation(.easeInOut(duration: 0.15), value: viewModel.uiState)
            .task { await viewModel.onAppear() }
            .navigationDestination(item: $viewModel.destination.session) { detailVM in
                SessionDetailView(viewModel: detailVM)
            }
            .navigationDestination(item: $viewModel.destination.levelLibrary) { libraryVM in
                LevelLibraryView(viewModel: libraryVM)
            }
        }
        .tint(DesignSystemAsset.fgStrong.swiftUIColor)
        .toolbar(viewModel.destination != nil ? .hidden : .visible, for: .tabBar)
    }
}

#Preview("홈") {
    HomeView(viewModel: HomeViewModel())
}

#Preview("로딩") {
    HomeLoadingView()
}
