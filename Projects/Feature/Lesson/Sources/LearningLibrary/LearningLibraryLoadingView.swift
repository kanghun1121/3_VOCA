import SwiftUI

import DesignSystem

struct LearningLibraryLoadingView: View {
    @ScaledMetric private var captionSize: CGFloat = 13.5

    var body: some View {
        VStack(spacing: 22) {
            HStack(spacing: 12) {
                PulseDot(delay: 0)
                PulseDot(delay: 0.18)
                PulseDot(delay: 0.36)
            }
            .frame(height: 24)
            Text("학습 라이브러리를 불러오는 중")
                .font(DesignSystemFontFamily.Pretendard.semiBold.swiftUIFont(size: captionSize))
                .tracking(-0.0675)
                .foregroundStyle(DesignSystemAsset.fgSubtle.swiftUIColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystemAsset.background.swiftUIColor)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("학습 라이브러리를 불러오는 중")
        .accessibilityAddTraits(.updatesFrequently)
    }
}

#Preview {
    LearningLibraryLoadingView()
}
