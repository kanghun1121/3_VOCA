import SwiftUI

import DomainInterface

public struct ChatBotView: View {
    @State private var viewModel: ChatBotViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(viewModel: ChatBotViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        ZStack {
            ChatBotContentView(viewModel: viewModel)

            if viewModel.isShowingLoginRequiredPopup {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)

                LoginRequiredPopupView(
                    onAppleRequest: viewModel.appleLoginRequested,
                    onAppleCompletion: viewModel.appleLoginCompleted,
                    onTapLater: {
                        viewModel.didTapLater()
                        dismiss()
                    }
                )
                .padding(.horizontal, 30)
                .transition(reduceMotion ? .opacity : .move(edge: .bottom))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: viewModel.isShowingLoginRequiredPopup)
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
        .toolbar(.hidden, for: .tabBar)
    }
}

#Preview("챗봇") {
    NavigationStack {
        ChatBotView(viewModel: ChatBotViewModel(context: .init(
            term: WordDetail.previewFixture.term,
            sentence: WordDetail.previewFixture.examples[0].en,
            levelLabel: "초급"
        )))
    }
}
