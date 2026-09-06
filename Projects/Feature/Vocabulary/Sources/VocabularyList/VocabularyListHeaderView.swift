import SwiftUI

import DesignSystem

struct VocabularyListHeaderView: View {
    let level: Int
    let lessonNumber: Int
    let wordCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(wordCount)개 단어")
                .font(DesignSystemFontFamily.Pretendard.extraBold.swiftUIFont(size: 28))
                .foregroundStyle(DesignSystemAsset.fgStrong.swiftUIColor)
                .kerning(-0.025 * 28)
            Text("Level \(level) · Session \(lessonNumber)")
                .font(DesignSystemFontFamily.Pretendard.regular.swiftUIFont(size: 14))
                .foregroundStyle(DesignSystemAsset.fgMuted.swiftUIColor)
                .padding(.top, 4)
        }
    }
}

