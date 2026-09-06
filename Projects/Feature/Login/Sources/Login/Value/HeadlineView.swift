import SwiftUI

import DesignSystem

struct HeadlineView: View {
    @ScaledMetric private var headlineSize: CGFloat = 32

    var body: some View {
        let highlighted = Text("3초 안에").foregroundStyle(DesignSystemAsset.game.swiftUIColor)
        Text("단어를 \(highlighted)\n떠올리는 힘")
            .font(DesignSystemFontFamily.Pretendard.extraBold.swiftUIFont(size: headlineSize))
            .foregroundStyle(DesignSystemAsset.fgStrong.swiftUIColor)
            .kerning(headlineSize * -0.025)
    }
}
