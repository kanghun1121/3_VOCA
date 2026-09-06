import SwiftUI

import DesignSystem

struct HeroContentView: View {
    let width: Double

    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                stops: [
                    .init(color: DesignSystemAsset.game100.swiftUIColor, location: 0),
                    .init(color: DesignSystemAsset.white.swiftUIColor, location: 1)
                ],
                startPoint: UnitPoint(x: 0.28, y: 0),
                endPoint: UnitPoint(x: 0.72, y: 1)
            )
            .ignoresSafeArea()

            FloatingWordCardView(word: "persevere", meaning: "끈기 있게 계속하다", tagKind: .know)
                .rotationEffect(.degrees(-6))
                .offset(x: 36, y: 86)
                .accessibilityHidden(true)

            FloatingWordCardView(word: "ambiguous", meaning: "모호한", tagKind: .time)
                .rotationEffect(.degrees(5))
                .offset(x: width - 220 - 28, y: 162)
                .accessibilityHidden(true)

            FloatingWordCardView(word: "profound", meaning: "깊은, 심오한", tagKind: .know)
                .rotationEffect(.degrees(-3))
                .offset(x: 44, y: 264)
                .accessibilityHidden(true)

            Circle()
                .fill(DesignSystemAsset.game.swiftUIColor.opacity(0.4))
                .frame(width: 8, height: 8)
                .offset(x: width - 60 - 8, y: 100)
                .accessibilityHidden(true)

            Circle()
                .fill(DesignSystemAsset.primary.swiftUIColor.opacity(0.5))
                .frame(width: 6, height: 6)
                .offset(x: 24, y: 220)
                .accessibilityHidden(true)

            Circle()
                .fill(DesignSystemAsset.cautionary.swiftUIColor.opacity(0.3))
                .frame(width: 10, height: 10)
                .offset(x: width - 100 - 10, y: 460 - 60 - 10)
                .accessibilityHidden(true)
        }
    }
}
