import SwiftUI

import DesignSystem
import DomainInterface

import SwiftUINavigation

public struct RecognitionGameView: View {
    @Bindable private var viewModel: RecognitionViewModel

    public init(viewModel: RecognitionViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            GameBackground()

            switch viewModel.viewState {
            case .loading:
                ProgressView()
                    .tint(DesignSystemAsset.white.swiftUIColor)

            case .active, .revealing:
                if let word = viewModel.currentWord {
                    RecognitionActivePhaseView(
                        word: word,
                        isRevealing: viewModel.viewState == .revealing,
                        countdown: viewModel.countdown,
                        ringProgress: viewModel.ringProgress,
                        onDismiss: viewModel.closeButtonTapped,
                        onRemembered: viewModel.rememberedButtonTapped,
                        onForgot: viewModel.forgotButtonTapped
                    )
                }
            }
        }
        .onAppear { viewModel.start() }
        .toolbar(.hidden, for: .navigationBar)
        .alert($viewModel.destination.alert) { action in
            viewModel.alertButtonTapped(action)
        }
    }
}

// MARK: - 활성/공개 단계

private struct RecognitionActivePhaseView: View {
    let word: Lesson.Word
    let isRevealing: Bool
    let countdown: Int
    let ringProgress: Double
    let onDismiss: () -> Void
    let onRemembered: () -> Void
    let onForgot: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            RecognitionGameHeader(onDismiss: onDismiss)
            RecognitionView(
                word: word,
                countdown: countdown,
                ringProgress: ringProgress,
                isRevealing: isRevealing,
                onRemembered: onRemembered,
                onForgot: onForgot
            )
        }
        .animation(.easeInOut(duration: 0.2), value: isRevealing)
    }
}

// MARK: - 헤더

private struct RecognitionGameHeader: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            StageSegmentBar(currentStage: 0)
                .padding(.top, 6)
            RecognitionCloseRow(onDismiss: onDismiss)
        }
    }
}

private struct RecognitionCloseRow: View {
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

