import SwiftUI

import DesignSystem
import DomainInterface

struct WordDetailPageView: View {
    let viewState: WordDetailViewModel.ViewState?
    let onPronunciationTapped: (String) -> Void
    let onChunkReaderTapped: (WordDetail.Example) -> Void
    let onChatBotTapped: (WordDetail, WordDetail.Example) -> Void

    var body: some View {
        ScrollView {
            switch viewState {
            case .loaded(let state):
                WordDetailContentView(
                    state: state,
                    onPronunciationTapped: onPronunciationTapped,
                    onChunkReaderTapped: onChunkReaderTapped,
                    onChatBotTapped: { example in onChatBotTapped(state, example) }
                )
            case .error(let message):
                Text(message)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .containerRelativeFrame(.vertical)
            case .loading, nil:
                WordDetailSkeletonContentView()
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("단어 정보 불러오는 중")
            }
        }
        .scrollIndicators(.hidden)
        .background(DesignSystemAsset.background.swiftUIColor)
    }
}
