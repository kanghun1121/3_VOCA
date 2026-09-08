import SwiftUI

import DomainInterface
import FeatureWord
import FeatureWordGame

import SwiftUINavigation

public struct LessonDetailView: View {
    @Bindable private var viewModel: LessonDetailViewModel

    public init(viewModel: LessonDetailViewModel) {
        _viewModel = Bindable(viewModel)
    }

    public var body: some View {
        Group {
            switch viewModel.uiState {
            case .loading:
                LessonDetailContentView(
                    state: .preview(id: "placeholder"),
                    learningHistory: .preview,
                    onGameTapped: {},
                    onWordListTapped: {}
                )
                .redacted(reason: .placeholder)
                .allowsHitTesting(false)
            case .loaded(let state):
                LessonDetailContentView(
                    state: state,
                    learningHistory: viewModel.learningHistory,
                    onGameTapped: viewModel.didTapGame,
                    onWordListTapped: viewModel.didTapWordList
                )
            case .error(let message):
                Text(message)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task { await viewModel.onAppear() }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $viewModel.destination.wordList) { wordListVM in
            WordListView(viewModel: wordListVM)
        }
        .navigationDestination(item: $viewModel.destination.wordGame) { wordGameVM in
            WordGameView(viewModel: wordGameVM)
        }
    }
}
