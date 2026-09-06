import SwiftUI

import DesignSystem
import FeatureLesson

import SwiftUINavigation

struct LevelLibraryView: View {
    @State private var viewModel: LevelLibraryViewModel

    init(viewModel: LevelLibraryViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            switch viewModel.uiState {
            case .loading:
                HomeLoadingView()
            case .success(let state):
                ScrollView {
                    HomeLevelList(
                        levels: state.levels,
                        expandedLevelIDs: viewModel.expandedLevelIDs,
                        onLevelTapped: { viewModel.didTapLevel(id: $0) },
                        onLessonTapped: { viewModel.didTapLesson(id: $0) }
                    )
                }
                .background(DesignSystemAsset.background.swiftUIColor)
            case .error(let message):
                ContentUnavailableView(message, systemImage: "exclamationmark.triangle")
            }
        }
        .navigationTitle("학습 라이브러리")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.onAppear() }
        .navigationDestination(item: $viewModel.destination.lesson) { detailVM in
            LessonDetailView(viewModel: detailVM)
        }
    }
}
