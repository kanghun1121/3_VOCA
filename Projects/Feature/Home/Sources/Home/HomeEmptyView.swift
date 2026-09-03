import SwiftUI

import DesignSystem

struct HomeEmptyView: View {
    @ScaledMetric private var captionSize: CGFloat = 13.5

    var body: some View {
        VStack(spacing: 12) {
            Text("아직 학습 기록이 없어요")
                .font(DesignSystemFontFamily.Pretendard.semiBold.swiftUIFont(size: captionSize))
                .tracking(-0.0675)
                .foregroundStyle(DesignSystemAsset.fgSubtle.swiftUIColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystemAsset.background.swiftUIColor)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("아직 학습 기록이 없어요")
    }
}

#Preview {
    HomeEmptyView()
}
