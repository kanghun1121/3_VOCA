import SwiftUI

import DesignSystem

struct WordCardTagPillView: View {
    enum Kind {
        case know
        case time
    }

    @ScaledMetric private var pillTextSize: CGFloat = 10

    let kind: Kind

    var body: some View {
        switch kind {
        case .know:
            Text("✓ 안다")
                .font(DesignSystemFontFamily.Pretendard.extraBold.swiftUIFont(size: pillTextSize))
                .foregroundStyle(DesignSystemAsset.positive.swiftUIColor)
                .kerning(pillTextSize * 0.04)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(DesignSystemAsset.positive100.swiftUIColor)
                .clipShape(Capsule())
        case .time:
            Text("3s")
                .font(DesignSystemFontFamily.Pretendard.extraBold.swiftUIFont(size: pillTextSize))
                .foregroundStyle(DesignSystemAsset.cautionary.swiftUIColor)
                .kerning(pillTextSize * 0.04)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(DesignSystemAsset.cautionary100.swiftUIColor)
                .clipShape(Capsule())
        }
    }
}
