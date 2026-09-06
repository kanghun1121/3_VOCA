import SwiftUI

import DesignSystem

struct FloatingWordCardHeaderView: View {
    @ScaledMetric private var wordSize: CGFloat = 18

    let word: String
    let tagKind: WordCardTagPillView.Kind

    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            Text(word)
                .font(DesignSystemFontFamily.Pretendard.extraBold.swiftUIFont(size: wordSize))
                .foregroundStyle(DesignSystemAsset.fgStrong.swiftUIColor)
                .kerning(wordSize * -0.012)
            Spacer()
            WordCardTagPillView(kind: tagKind)
        }
    }
}
