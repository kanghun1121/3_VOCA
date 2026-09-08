import SwiftUI

import DesignSystem
import DomainInterface

struct WordDetailContentView: View {
    let state: WordDetail
    let onPronunciationTapped: (String) -> Void
    let onChunkReaderTapped: (WordDetail.Example) -> Void
    let onChatBotTapped: (WordDetail.Example) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            WordDetailHeaderView(term: state.term, pronunciation: state.pronunciation) {
                onPronunciationTapped(state.term)
            }
            .padding(.bottom, 22)

            WordDetailDefinitionsView(groups: state.groupedDefinitions())
                .padding(.bottom, 28)

            if !state.examples.isEmpty {
                WordDetailExamplesView(
                    term: state.term,
                    examples: state.sortedExamples,
                    onChunkReaderTapped: onChunkReaderTapped,
                    onChatBotTapped: onChatBotTapped
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 32)
    }
}
