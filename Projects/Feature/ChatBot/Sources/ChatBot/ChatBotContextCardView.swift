import SwiftUI

import DesignSystem

/// 문법 분석 대상 예문을 요약해 보여주는 카드. `문법 분석 · <레벨>` 칩 아래 대상 단어가
/// 노란 배경으로 하이라이트된 문장을 렌더한다.
struct ChatBotContextCardView: View {
    let context: ChatBotContext
    // NLTagger 파이프라인은 view 생성/body 평가를 막지 않도록 task()에서 채운다
    @State private var highlightedSentence: Text?

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 6) {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 10))
                Text("문법 분석 · \(context.levelLabel)")
                    .font(DesignSystemFontFamily.Pretendard.extraBold.swiftUIFont(size: 12))
                    .tracking(0.36)
            }
            .foregroundStyle(DesignSystemAsset.study300.swiftUIColor)

            (highlightedSentence ?? Text(context.sentence))
                .font(DesignSystemFontFamily.Pretendard.semiBold.swiftUIFont(size: 15))
                .foregroundStyle(DesignSystemAsset.fgStrong.swiftUIColor)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystemAsset.study100.swiftUIColor.opacity(0.33))
        .clipShape(.rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(DesignSystemAsset.study100.swiftUIColor, lineWidth: 1)
        }
        .task(id: "\(context.term)|\(context.sentence)") {
            highlightedSentence = Text(SentenceHighlighter.highlighted(
                sentence: context.sentence,
                keyword: context.term,
                font: DesignSystemFontFamily.Pretendard.semiBold.swiftUIFont(size: 15),
                highlightFont: DesignSystemFontFamily.Pretendard.bold.swiftUIFont(size: 15)
            ))
        }
    }
}

#Preview("ChatBotContextCard") {
    ChatBotContextCardView(context: .init(
        term: "address",
        sentence: "Please write your home address on this form.",
        levelLabel: "초급"
    ))
    .padding(16)
}
