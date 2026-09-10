import SwiftUI

import DesignSystem

struct SplashContentView: View {
    private let markSize: CGFloat = 156
    private let markCornerRadiusRatio: CGFloat = 0.2237

    var body: some View {
        VStack(spacing: 0) {
            DesignSystemAsset.splashMark.swiftUIImage
                .resizable()
                .scaledToFit()
                .frame(width: markSize, height: markSize)
                .clipShape(RoundedRectangle(cornerRadius: markSize * markCornerRadiusRatio, style: .continuous))
                .accessibilityHidden(true)

            Text("3초 단어")
                .font(DesignSystemFontFamily.Pretendard.extraBold.swiftUIFont(size: 30))
                .kerning(-1.26)
                .foregroundStyle(DesignSystemAsset.fgStrong.swiftUIColor)
                .padding(.top, 15)

            Text("하루 3초, 단어 한 입")
                .font(DesignSystemFontFamily.Pretendard.semiBold.swiftUIFont(size: 15))
                .kerning(-0.1875)
                .foregroundStyle(DesignSystemAsset.splashTagline.swiftUIColor)
                .padding(.top, 12)
        }
        .padding(.horizontal, 48)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
