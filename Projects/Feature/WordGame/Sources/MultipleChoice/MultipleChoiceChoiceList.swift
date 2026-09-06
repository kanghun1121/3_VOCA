import SwiftUI

import DomainInterface

struct MultipleChoiceChoiceList: View {
    let word: Lesson.Word
    let choices: [String]
    let viewState: MultipleChoiceViewModel.ViewState
    let onChoiceTap: (String) -> Void

    var body: some View {
        VStack(spacing: 12) {
            ForEach(choices, id: \.self) { choice in
                ChoiceButton(
                    text: choice,
                    state: choiceButtonState(for: choice),
                    onTap: { onChoiceTap(choice) }
                )
            }
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 40)
    }

    private func choiceButtonState(for choice: String) -> ChoiceButtonState {
        switch viewState {
        case .active:
            return .idle
        case .revealed(let selected):
            let correct = word.primaryMeaning
            if choice == correct {
                return .correct
            } else if choice == selected {
                return .incorrect
            }
            return .idle
        }
    }
}
