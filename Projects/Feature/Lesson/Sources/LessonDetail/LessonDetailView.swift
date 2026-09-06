import SwiftUI

import DomainInterface
import FeatureVocabulary
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
                    onVocabularyListTapped: {}
                )
                .redacted(reason: .placeholder)
                .allowsHitTesting(false)
            case .loaded(let state):
                LessonDetailContentView(
                    state: state,
                    learningHistory: viewModel.learningHistory,
                    onGameTapped: viewModel.didTapGame,
                    onVocabularyListTapped: viewModel.didTapVocabularyList
                )
            case .error(let message):
                Text(message)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task { await viewModel.onAppear() }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $viewModel.destination.vocabularyList) { vocabularyListVM in
            VocabularyListView(viewModel: vocabularyListVM)
        }
        .navigationDestination(item: $viewModel.destination.wordGame) { wordGameVM in
            WordGameView(viewModel: wordGameVM)
        }
    }
}
