import SwiftUI

import DesignSystem

import SwiftUINavigation

public struct LearningLibraryView: View {
    @State private var viewModel: LearningLibraryViewModel

    public init(viewModel: LearningLibraryViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        Group {
            switch viewModel.uiState {
            case .loading:
                LearningLibraryLoadingView()
            case .success(let state):
                ScrollView {
                    LevelList(
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
