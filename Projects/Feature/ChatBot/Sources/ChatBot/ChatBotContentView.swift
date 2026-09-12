import SwiftUI

import DesignSystem

struct ChatBotContentView: View {
    @Bindable var viewModel: ChatBotViewModel
    @State private var chatAreaHeight: CGFloat = 0
    @FocusState private var isInputFocused: Bool
    @State private var isScrolledToBottom = true

    private static let bottomAnchorID = "chat-bottom-anchor"
    private static let bottomThreshold: CGFloat = 300

    var body: some View {
        chatArea
            .background(DesignSystemAsset.background.swiftUIColor)
    }

    private var chatArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ChatBotContextCardView(context: viewModel.context)

                    ForEach(viewModel.messages) { message in
                        let isLastMessage = message.id == viewModel.messages.last?.id

                        ChatBotMessageRow(
                            message: message,
                            isActivelyStreaming: viewModel.isStreaming && isLastMessage
                        )
                        .id(message.id)
                        .frame(
                            minHeight: isLastMessage && message.role == .assistant && !message.isFromHistory
                                ? chatAreaHeight
                                : nil,
                            alignment: .top
                        )
                    }

                    Color.clear
                        .frame(height: 1)
                        .id(Self.bottomAnchorID)
                }
                .padding(16)
            }
            .onGeometryChange(for: CGFloat.self) { geometryProxy in
                geometryProxy.size.height
            } action: { newHeight in
                chatAreaHeight = newHeight
            }
            .onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.contentOffset.y + geometry.containerSize.height
                    >= geometry.contentSize.height - Self.bottomThreshold
            } action: { _, isAtBottom in
                isScrolledToBottom = isAtBottom
            }
            .onChange(of: viewModel.messages.count) {
                guard viewModel.isStreaming else { return }
                guard let lastUserMessageID = viewModel.messages.last(where: { $0.role == .user })?.id else { return }
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo(lastUserMessageID, anchor: .top)
                }
            }
            .task {
                await viewModel.load()
                proxy.scrollTo(Self.bottomAnchorID, anchor: .bottom)
            }
            .overlay(alignment: .bottom) {
                if !isScrolledToBottom {
                    scrollToBottomButton(proxy: proxy)
                        .padding(.bottom, 8)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { isInputFocused = false }
        .modifier(ChatBotBottomBar { inputBar })
    }

    private func scrollToBottomButton(proxy: ScrollViewProxy) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo(Self.bottomAnchorID, anchor: .bottom)
            }
        } label: {
            Image(systemName: "chevron.down")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(DesignSystemAsset.fgMuted.swiftUIColor)
                .frame(width: 36, height: 36)
                .background(DesignSystemAsset.background.swiftUIColor, in: .circle)
                .overlay {
                    Circle().stroke(DesignSystemAsset.border.swiftUIColor, lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("최하단으로 이동")
    }

    private var inputBar: some View {
        ChatBotInputBar(
            placeholder: "\(viewModel.context.term)에 대해 물어보세요",
            text: $viewModel.input,
            state: viewModel.isStreaming ? .stop : .send(isEnabled: viewModel.canSend),
            isFocused: $isInputFocused,
            onSend: { viewModel.didTapSend() },
            onStop: { viewModel.didTapStop() }
        )
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 14)
    }
}

private struct ChatBotBottomBar<Bar: View>: ViewModifier {
    @ViewBuilder let bar: Bar

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.safeAreaBar(edge: .bottom) { bar }
        } else {
            content.safeAreaInset(edge: .bottom) { bar }
        }
    }
}
