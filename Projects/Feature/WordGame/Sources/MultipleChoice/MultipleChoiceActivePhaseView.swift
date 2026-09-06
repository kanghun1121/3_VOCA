import SwiftUI

import DomainInterface

struct MultipleChoiceActivePhaseView: View {
    let word: Lesson.Word
    let choices: [String]
    let viewState: MultipleChoiceViewModel.ViewState
    let onDismiss: () -> Void
    let onChoiceTap: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            MultipleChoiceGameHeader(onDismiss: onDismiss)
            MultipleChoiceView(
                word: word,
                choices: choices,
                viewState: viewState,
                onChoiceTap: onChoiceTap
            )
        }
    }
}
