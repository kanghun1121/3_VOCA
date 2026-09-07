import SwiftUI

import DesignSystem
import Dependencies

public struct VocabularyListView: View {
    @Bindable private var viewModel: VocabularyListViewModel
    @Environment(\.dismiss) private var dismiss

    public init(viewModel: VocabularyListViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Group {
            switch viewModel.viewState {
            case .loading:
                VocabularyListSkeletonView()
            case .loaded(let state):
                VocabularyListContentView(
                    state: state,
                    learningHistory: viewModel.learningHistory,
                    onWordTapped: viewModel.didTapWord
                )
            case .error(let message):
                Text(message)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task { await viewModel.load() }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(
                    "뒤로",
                    systemImage: "chevron.left",
                    action: dismiss.callAsFunction
                )
                .fontWeight(.semibold)
                .foregroundStyle(DesignSystemAsset.fgStrong.swiftUIColor)
            }
        }
        .navigationDestination(item: $viewModel.destination.wordDetail) { wordDetailVM in
            WordDetailView(viewModel: wordDetailVM)
        }
    }
}

#Preview("로딩") {
    let vm = withDependencies {
        $0.loadVocabularyListUseCase = .previewLoading
    } operation: {
        VocabularyListViewModel(lessonID: "preview")
    }
    NavigationStack {
        VocabularyListView(viewModel: vm)
    }
}
