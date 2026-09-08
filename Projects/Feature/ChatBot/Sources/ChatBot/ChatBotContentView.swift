import SwiftUI

import DesignSystem

/// 문법 분석 화면 본문 — ChatBotContextCard는 고정 헤더가 아니라 채팅 컨텐츠의 첫 항목이라
/// 메시지와 함께 스크롤되어 사라진다. 입력바만 그 위에 플로팅 레이어로 얹힌다
/// (`chatArea`의 `.safeAreaInset` 참고) — 입력바가 다중 행으로 늘어나도 마지막 메시지가
/// 가려지지 않는다.
///
/// 전송 시 ChatGPT처럼 방금 보낸 질문을 화면 맨 위로 스크롤한다 — 그 아래 AI 응답 자리에
/// 뷰포트 높이만큼의 최소 높이를 줘서, 응답이 아직 짧거나 비어 있어도 빈 공간이 남는다.
struct ChatBotContentView: View {
    @Bindable var viewModel: ChatBotViewModel
    // GeometryReader는 안전 영역(safe area)을 무시하고 자신에게 주어진 프레임을 그대로
    // 차지해버려 컨텐츠가 네비게이션 바 아래로 파고드는 문제가 있었다. 레이아웃에 영향을
    // 주지 않고 크기만 관찰하는 onGeometryChange로 측정해 안전 영역을 다시 존중하게 한다.
    @State private var chatAreaHeight: CGFloat = 0
    /// 화면 아무 곳이나 탭해도 키보드를 내려야 해서, 포커스는 입력바가 아니라 여기서
    /// 소유하고 `ChatBotInputBar`에는 바인딩만 내려보낸다.
    @FocusState private var isInputFocused: Bool
    /// 스크롤이 콘텐츠 최하단에 있는지 — false일 때만 "최하단으로 이동" 버튼을 보여준다.
    @State private var isScrolledToBottom = true

    private static let bottomAnchorID = "chat-bottom-anchor"
    /// 이 값보다 콘텐츠 하단에 가까우면 최하단으로 간주해 버튼을 숨긴다 — 스크롤을
    /// 어느 정도 위로 올렸을 때만 버튼이 뜨도록 화면 하나 높이에 가깝게 잡는다.
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
                            minHeight: isLastMessage && message.role == .assistant
                                ? chatAreaHeight
                                : nil,
                            alignment: .top
                        )
                    }

                    // 최하단 스크롤 앵커 — 실제로 그려지는 콘텐츠는 없다.
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
                guard let lastUserMessageID = viewModel.messages.last(where: { $0.role == .user })?.id else { return }
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo(lastUserMessageID, anchor: .top)
                }
            }
            .overlay(alignment: .bottom) {
                if !isScrolledToBottom {
                    scrollToBottomButton(proxy: proxy)
                        .padding(.bottom, 8)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // 배경이 투명해 기본 상태로는 빈 공간이 탭을 받지 못한다 — contentShape로
        // 전체 영역을 탭 가능하게 만든 뒤, 탭하면 키보드를 내린다. 메시지/버튼 등
        // 실제 컨트롤 위를 탭하면 그 컨트롤이 먼저 탭을 소비해 이 제스처까지 오지 않는다.
        .contentShape(Rectangle())
        .onTapGesture { isInputFocused = false }
        .modifier(ChatBotBottomBar { inputBar })
    }

    /// 스크롤 최하단 이동 버튼 — 흰 배경 + 옅은 테두리/그림자로, 입력바 iOS18
    /// 폴백(`ChatBotInputBarBackground`)·어시스턴트 말풍선과 같은 "떠 있는 흰
    /// 표면" 톤을 재사용한다.
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
    }

    private var inputBar: some View {
        ChatBotInputBar(
            placeholder: "\(viewModel.context.term)에 대해 물어보세요",
            text: $viewModel.input,
            state: viewModel.isStreaming ? .cancel : .send(isEnabled: viewModel.canSend),
            isFocused: $isInputFocused,
            onSend: { viewModel.didTapSend() },
            onCancel: { viewModel.didTapCancel() }
        )
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 14)
    }
}

/// 입력바를 하단 안전영역에 붙이는 방식 — iOS 26+에서는 `safeAreaBar`를 써서 채팅
/// ScrollView 하단에 시스템 scroll edge effect(부드러운 블러 페이드)가 걸리게 한다.
/// `safeAreaInset`은 레이아웃만 담당하고 엣지 이펙트를 확장하지 않아 효과가 없다.
/// iOS 18~25에는 대응 API가 없어 기존 `safeAreaInset` 동작 그대로 폴백한다.
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
