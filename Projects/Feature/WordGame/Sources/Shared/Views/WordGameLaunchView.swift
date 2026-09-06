import SwiftUI

import DesignSystem

struct WordGameLaunchView: View {
    let onStart: () -> Void

    @State private var brandOffset: Double = 10
    @State private var brandOpacity: Double = 0

    var body: some View {
        ZStack {
            GameBackground()
            LaunchBrandView(offset: brandOffset, opacity: brandOpacity)
            LaunchTapHintView()
        }
        .contentShape(Rectangle())
        .onTapGesture { onStart() }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("게임 시작")
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation(.timingCurve(
                0.3, 0, 0, 1,
                duration: 0.62
            )) {
                brandOffset = 0
                brandOpacity = 1
            }
        }
    }
}

// MARK: - 중앙 브랜드

private struct LaunchBrandView: View {
    let offset: Double
    let opacity: Double

    var body: some View {
        VStack(spacing: 14) {
            Text("3초 단어")
                .font(DesignSystemFontFamily.Pretendard.extraBold.swiftUIFont(size: 46))
                .foregroundStyle(DesignSystemAsset.white.swiftUIColor)
                .kerning(-0.035 * 46)
                .shadow(
                    color: DesignSystemAsset.gameDeep.swiftUIColor.opacity(0.6),
                    radius: 20,
                    x: 0,
                    y: 4
                )

            Text("단어 속으로 들어갈 시간")
                .font(DesignSystemFontFamily.Pretendard.regular.swiftUIFont(size: 15))
                .foregroundStyle(DesignSystemAsset.white.swiftUIColor.opacity(0.62))
                .kerning(0.01 * 15)
        }
        .offset(y: offset)
        .opacity(opacity)
    }
}

// MARK: - 하단 탭 힌트

private struct LaunchTapHintView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("탭하여 시작")
                .font(DesignSystemFontFamily.Pretendard.medium.swiftUIFont(size: 15))
                .foregroundStyle(DesignSystemAsset.white.swiftUIColor.opacity(0.38))
                .padding(.bottom, 30)
        }
    }
}
