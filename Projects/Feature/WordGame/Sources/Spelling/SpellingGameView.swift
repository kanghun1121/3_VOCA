import SwiftUI

import DesignSystem
import DomainInterface

import SwiftUINavigation

public struct SpellingGameView: View {
    @Bindable private var viewModel: SpellingViewModel
    @FocusState private var isKeyboardFocused: Bool

    public init(viewModel: SpellingViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            GameBackground()

            if let word = viewModel.currentWord {
                SpellingActivePhaseView(
                    word: word,
                    slots: viewModel.slots,
                    viewState: viewModel.viewState,
                    onDismiss: viewModel.closeButtonTapped,
                    onSkip: viewModel.skipButtonTapped
                )
            }

            // 시스템 키보드 진입점 — 화면에 보이지 않음
            TextField("", text: $viewModel.inputText)
                .frame(width: 1, height: 1)
                .opacity(0.001)
                .focused($isKeyboardFocused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .keyboardType(.asciiCapable)
        }
        .onAppear {
            viewModel.load()
            isKeyboardFocused = true
        }
        .onChange(of: viewModel.viewState) { _, state in
            switch state {
            case .revealing:
                isKeyboardFocused = false
            case .active:
                if !isKeyboardFocused { isKeyboardFocused = true }
            default:
                break
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .alert($viewModel.destination.alert) { action in
            viewModel.alertButtonTapped(action)
        }
    }
}

// MARK: - 활성 단계

private struct SpellingActivePhaseView: View {
    let word: Lesson.Word
    let slots: [SpellingViewModel.SlotState]
    let viewState: SpellingViewModel.ViewState
    let onDismiss: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            SpellingGameHeader(onDismiss: onDismiss)

            SpellingView(
                word: word,
                slots: slots,
                viewState: viewState,
                onSkip: onSkip
            )
        }
    }
}

// MARK: - 헤더

private struct SpellingGameHeader: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            StageSegmentBar(currentStage: 2)
                .padding(.top, 6)

            SpellingHeaderRow(onDismiss: onDismiss)
        }
    }
}

private struct SpellingHeaderRow: View {
    let onDismiss: () -> Void

    var body: some View {
        HStack {
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DesignSystemAsset.white.swiftUIColor)
                    .frame(width: 40, height: 40)
            }
            .padding(.leading, 10)
            .accessibilityLabel("닫기")

            Spacer()

            Spacer().frame(width: 40)
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
    }
}
