import SwiftUI

import DomainInterface
import FeatureVocabulary
import FeatureWordGame

import SwiftUINavigation

public struct SessionDetailView: View {
    @Bindable private var viewModel: SessionDetailViewModel

    public init(viewModel: SessionDetailViewModel) {
        _viewModel = Bindable(viewModel)
    }

    public var body: some View {
        Group {
            switch viewModel.viewState {
            case .loading:
                SessionDetailContentView(
                    state: .previewWithRecord(id: "placeholder"),
                    onGameTapped: {},
                    onVocabularyListTapped: {}
                )
                .redacted(reason: .placeholder)
                .allowsHitTesting(false)
            case .loaded(let state):
                SessionDetailContentView(
                    state: state,
                    onGameTapped: viewModel.didTapGame,
                    onVocabularyListTapped: viewModel.didTapVocabularyList
                )
            case .error(let message):
                Text(message)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task { await viewModel.load() }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $viewModel.destination.vocabularyList) { vocabularyListVM in
            VocabularyListView(viewModel: vocabularyListVM)
        }
        .navigationDestination(item: $viewModel.destination.wordGame) { wordGameVM in
            WordGameView(viewModel: wordGameVM)
        }
    }
}
