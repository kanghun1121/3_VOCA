import SwiftUI

import DesignSystem

/// 사용자 질문 말풍선 — 우측 정렬, 초록 배경, 우상단만 각진 꼬리 모양.
struct ChatBotUserBubbleView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(DesignSystemFontFamily.Pretendard.semiBold.swiftUIFont(size: 14.5))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(DesignSystemAsset.study300.swiftUIColor)
            .clipShape(.rect(
                topLeadingRadius: 16,
                bottomLeadingRadius: 16,
                bottomTrailingRadius: 4,
                topTrailingRadius: 16
            ))
    }
}

#Preview("유저 말풍선") {
    ChatBotUserBubbleView(text: "address가 동사로 쓰이면 뜻이 어떻게 달라져?")
        .padding(16)
}
