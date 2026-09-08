import SwiftUI

import DesignSystem

struct LessonHeaderSection: View {
    let level: Int
    let lessonNumber: Int
    let wordCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("LEVEL \(level) · LESSON \(lessonNumber)")
                .font(DesignSystemFontFamily.Pretendard.bold.swiftUIFont(size: 14))
                .foregroundStyle(DesignSystemAsset.primary.swiftUIColor)
            Text("\(wordCount)개 단어")
                .font(DesignSystemFontFamily.Pretendard.extraBold.swiftUIFont(size: 33))
                .foregroundStyle(DesignSystemAsset.fgStrong.swiftUIColor)
        }
    }
}
