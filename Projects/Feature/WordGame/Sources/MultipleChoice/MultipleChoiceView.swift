import SwiftUI

import DomainInterface

struct MultipleChoiceView: View {
    let word: Lesson.Word
    let choices: [String]
    let viewState: MultipleChoiceViewModel.ViewState
    let onChoiceTap: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            MultipleChoiceWordHeader(word: word)
            Spacer()
            MultipleChoiceChoiceList(
                word: word,
                choices: choices,
                viewState: viewState,
                onChoiceTap: onChoiceTap
            )
        }
    }
}
