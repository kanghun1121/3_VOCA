import SwiftUI

import DesignSystem
import DomainInterface

struct WordPreviewSection: View {
    let words: [Session.Word]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isExpanded = false
    private let previewLimit = 6

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("이번 세션의 단어 (\(words.count))")
                .font(DesignSystemFontFamily.Pretendard.bold.swiftUIFont(size: 14))
                .foregroundStyle(DesignSystemAsset.fgMuted.swiftUIColor)
                .tracking(0.26)
                .padding(.bottom, 12)

            ForEach(Array(words.enumerated()), id: \.offset) { index, item in
                if index < previewLimit || isExpanded {
                    WordPreviewRow(item: item)
                        .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
                        .animation(
                            .easeOut(duration: 0.2)
                                .delay(Double(max(0, index - previewLimit)) * 0.04),
                            value: isExpanded
                        )
                }
            }

            if !isExpanded, words.count > previewLimit {
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isExpanded = true
                    }
                } label: {
                    Text("+ \(words.count - previewLimit) more")
                        .font(DesignSystemFontFamily.Pretendard.medium.swiftUIFont(size: 14))
                        .foregroundStyle(DesignSystemAsset.fgMuted.swiftUIColor)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 12)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct WordPreviewRow: View {
    let item: Session.Word

    var body: some View {
        VStack(spacing: 0) {
            WordPreviewRowContent(item: item)
            Divider()
        }
    }
}

private struct WordPreviewRowContent: View {
    let item: Session.Word

    var body: some View {
        HStack {
            Text(item.term)
                .font(DesignSystemFontFamily.Pretendard.semiBold.swiftUIFont(size: 16))
                .foregroundStyle(DesignSystemAsset.fgStrong.swiftUIColor)
            Spacer()
            Text(item.primaryMeaning)
                .font(DesignSystemFontFamily.Pretendard.medium.swiftUIFont(size: 14))
                .foregroundStyle(DesignSystemAsset.fgMuted.swiftUIColor)
        }
        .padding(.vertical, 12)
    }
}
