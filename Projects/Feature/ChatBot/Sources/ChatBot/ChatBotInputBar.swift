import SwiftUI

import DesignSystem

/// 입력바 우측 원형 버튼의 상태 — 평상시엔 전송, 스트리밍 중엔 정지.
/// `isStreaming`/`canSend` 두 Bool로 따로 받으면 둘 다 참인 모순 조합이 타입상 허용돼
/// 버리므로, 그 상태를 표현 불가능하게 만드는 enum으로 대신한다.
enum ChatBotSendButtonState: Equatable {
    /// 전송 가능 여부에 따라 활성/비활성. 입력이 비어 있으면 `isEnabled == false`.
    case send(isEnabled: Bool)
    /// 스트리밍 진행 중 — 탭하면 정지(서브플랜 10, 구 취소). 항상 활성이다.
    case stop
}

/// 다중 행으로 자라는 입력 필드 + 원형 전송 버튼.
///
/// Figma 디자인 2개("빈 대화" / "입력 확장")는 이 컴포넌트 하나가 흡수하는 두 상태다 —
/// `axis: .vertical` + `lineLimit`으로 입력이 길어지면 필드가 자라고, `alignment: .bottom`이
/// 확장 시에도 전송 버튼을 하단에 고정한다.
struct ChatBotInputBar: View {
    let placeholder: String
    @Binding var text: String
    let state: ChatBotSendButtonState
    let maxLines: Int
    let onSend: () -> Void
    let onStop: () -> Void

    /// 포커스는 이 뷰가 소유하지 않는다 — 화면 아무 곳을 탭해도 같은 키보드를 내려야
    /// 해서, 상위(`ChatBotContentView`)가 소유하고 이 뷰는 바인딩만 받는다.
    var isFocused: FocusState<Bool>.Binding

    init(
        placeholder: String,
        text: Binding<String>,
        state: ChatBotSendButtonState,
        maxLines: Int = 5,
        isFocused: FocusState<Bool>.Binding,
        onSend: @escaping () -> Void,
        onStop: @escaping () -> Void
    ) {
        self.placeholder = placeholder
        _text = text
        self.state = state
        self.maxLines = maxLines
        self.isFocused = isFocused
        self.onSend = onSend
        self.onStop = onStop
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            TextField(placeholder, text: $text, axis: .vertical)
                .font(DesignSystemFontFamily.Pretendard.medium.swiftUIFont(size: 14.5))
                .foregroundStyle(DesignSystemAsset.fgStrong.swiftUIColor)
                .lineLimit(1...maxLines)
                // 한 줄일 때는 30pt(전송 버튼 높이) 박스 안에서 세로 중앙 정렬되고,
                // 여러 줄로 자라면 버튼 높이를 넘어서 자연스럽게 늘어난다.
                // 스트리밍 중에도 비활성화하지 않는다 — 다음 메시지를 미리 입력해 둘 수 있다.
                .frame(minHeight: 30)
                .focused(isFocused)

            sendButton
        }
        .padding(.leading, 16)
        .padding(.trailing, 6)
        .padding(.vertical, 7)
        .frame(minHeight: 44)
        .modifier(ChatBotInputBarBackground())
    }

    /// 배경(`study300`)과 30×30 크기는 두 상태가 같고 안의 글리프만 달라진다(Figma
    /// node-id=25-50) — 상태별로 뷰를 나누지 않고 아이콘만 분기한다.
    private var sendButton: some View {
        Button(action: state == .stop ? onStop : didTapSend) {
            buttonIcon
                .frame(width: 30, height: 30)
                .background(DesignSystemAsset.study300.swiftUIColor, in: .circle)
        }
        .buttonStyle(.plain)
        // 아이콘 전용 버튼이라 VoiceOver가 읽을 텍스트가 따로 필요하다 — 커스텀 라벨 뷰라
        // Button(_:systemImage:action:)를 못 쓰므로 accessibilityLabel로 직접 붙인다.
        .accessibilityLabel(state == .stop ? "정지" : "전송")
        .disabled(state == .send(isEnabled: false))
    }

    /// 전송 시에만 키보드를 내린다 — 정지는 스트리밍을 멈출 뿐이라, 이어서 다음 질문을
    /// 입력하려는 사용자의 포커스를 뺏지 않는다.
    private func didTapSend() {
        isFocused.wrappedValue = false
        onSend()
    }

    @ViewBuilder
    private var buttonIcon: some View {
        switch state {
        case .send:
            Image(systemName: "arrow.up")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
        case .stop:
            RoundedRectangle(cornerRadius: 3)
                .fill(.white)
                .frame(width: 10, height: 10)
        }
    }
}

/// 입력바 배경 재질 — iOS 26+에서는 Liquid Glass(`.glassEffect()`), 그 미만에서는 지금까지
/// 쓰던 `bgSubtle` 캡슐 배경 + 테두리로 폴백한다. 배포 타겟은 18.0을 유지하므로 분기 필요.
///
/// 기본 `.regular` 글래스는 투명도만 있고 색조가 없어, 챗봇 배경(흰색)과 거의 구분이 안
/// 됐다 — 폴백과 같은 `bgSubtle` 톤을 살짝 입혀 배경과 구분되게 한다.
private struct ChatBotInputBarBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(
                .regular.tint(DesignSystemAsset.bgSubtle.swiftUIColor),
                in: .rect(cornerRadius: 22)
            )
        } else {
            content
                .background(DesignSystemAsset.bgSubtle.swiftUIColor, in: .rect(cornerRadius: 22))
                .overlay {
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(DesignSystemAsset.border.swiftUIColor, lineWidth: 1)
                }
        }
    }
}

/// 프리뷰 전용 — `FocusState`는 프로퍼티 래퍼라 뷰 계층 안에서만 선언할 수 있어,
/// 프리뷰 클로저 대신 이 작은 래퍼 뷰가 대신 소유한다.
private struct ChatBotInputBarPreview: View {
    @State var text: String
    let state: ChatBotSendButtonState
    @FocusState private var isFocused: Bool

    var body: some View {
        ChatBotInputBar(
            placeholder: "address에 대해 물어보세요",
            text: $text,
            state: state,
            isFocused: $isFocused,
            onSend: {},
            onStop: {}
        )
        .padding(16)
    }
}

#Preview("빈 상태") {
    ChatBotInputBarPreview(text: "", state: .send(isEnabled: false))
}

#Preview("입력 확장") {
    ChatBotInputBarPreview(
        text: "이 문장에서 address라는 단어가 정확히 어떤 의미로 쓰인 건지 궁금해요.",
        state: .send(isEnabled: true)
    )
}

#Preview("스트리밍 중") {
    ChatBotInputBarPreview(text: "", state: .stop)
}
