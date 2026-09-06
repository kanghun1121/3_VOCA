import SwiftUI

import DesignSystem

struct FloatingWordCardView: View {
    let word: String
    let meaning: String
    let tagKind: WordCardTagPillView.Kind

    @ScaledMetric private var meaningSize: CGFloat = 12

    private let cardBaseColor = Color(
        red: 0.09,
        green: 0.09,
        blue: 0.09
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            FloatingWordCardHeaderView(word: word, tagKind: tagKind)
                .padding(.bottom, 4)
            Text(meaning)
                .font(DesignSystemFontFamily.Pretendard.regular.swiftUIFont(size: meaningSize))
                .foregroundStyle(DesignSystemAsset.fgMuted.swiftUIColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(width: 220)
        .background(DesignSystemAsset.white.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(
            color: cardBaseColor.opacity(0.12),
            radius: 16,
            x: 0,
            y: 12
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(cardBaseColor.opacity(0.04), lineWidth: 1)
        }
    }
}
