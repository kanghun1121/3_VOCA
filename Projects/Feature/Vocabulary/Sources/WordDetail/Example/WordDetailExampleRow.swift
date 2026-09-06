import SwiftUI

import DesignSystem
import DomainInterface

struct WordDetailExampleRow: View {
    let term: String
    let example: WordDetail.Example
    let onChunkReaderTapped: (WordDetail.Example) -> Void
    let onChatBotTapped: (WordDetail.Example) -> Void
    // NLTagger 파이프라인은 view 생성/body 평가를 막지 않도록 task()에서 채운다
    @State private var highlightedEnText: Text? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            (highlightedEnText ?? Text(example.en))
                .font(DesignSystemFontFamily.Pretendard.semiBold.swiftUIFont(size: 16))
                .foregroundStyle(DesignSystemAsset.fgStrong.swiftUIColor)

            Text(example.ko)
                .font(DesignSystemFontFamily.Pretendard.regular.swiftUIFont(size: 13))
                .foregroundStyle(DesignSystemAsset.fgMuted.swiftUIColor)

            ActionBar(
                example: example,
                onChunkReaderTapped: onChunkReaderTapped,
                onChatBotTapped: onChatBotTapped
            )
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystemAsset.study100.swiftUIColor.opacity(0.5))
        .clipShape(.rect(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(DesignSystemAsset.study100.swiftUIColor, lineWidth: 1)
        }
        .task(id: "\(term)|\(example.en)") {
            highlightedEnText = Text(SentenceHighlighter.highlighted(
                sentence: example.en,
                keyword: term,
                font: DesignSystemFontFamily.Pretendard.semiBold.swiftUIFont(size: 16),
                highlightFont: DesignSystemFontFamily.Pretendard.bold.swiftUIFont(size: 16)
            ))
        }
    }
}

/// 끊어읽기·챗봇 액션바 — 둘 다 모든 예문에 항상 노출한다. chunks는 모든 예문에
/// 존재하고, 챗봇에는 어떤 예문이든 물어볼 수 있어야 한다.
private struct ActionBar: View {
    let example: WordDetail.Example
    let onChunkReaderTapped: (WordDetail.Example) -> Void
    let onChatBotTapped: (WordDetail.Example) -> Void

    var body: some View {
        HStack(spacing: 12) {
            actionButton(icon: DesignSystemAsset.alignLeft, title: "끊어읽기") {
                onChunkReaderTapped(example)
            }
            actionButton(icon: DesignSystemAsset.messageSquare, title: "챗봇") {
                onChatBotTapped(example)
            }
        }
    }

    private func actionButton(
        icon: DesignSystemImages,
        title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label {
                Text(title)
                    .font(DesignSystemFontFamily.Pretendard.semiBold.swiftUIFont(size: 13))
            } icon: {
                icon.swiftUIImage
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 14, height: 14)
            }
            .foregroundStyle(DesignSystemAsset.study300.swiftUIColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .contentShape(.rect)
        .buttonStyle(.plain)
    }
}
