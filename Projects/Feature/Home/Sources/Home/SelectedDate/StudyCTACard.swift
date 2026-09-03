import SwiftUI

import DesignSystem

struct StudyCTACard: View {
    let onTapped: () -> Void

    var body: some View {
        Button(action: onTapped) {
            Content()
                .padding(22)
                .frame(maxWidth: .infinity)
                .background(Background())
        }
        .buttonStyle(.plain)
        .clipShape(.rect(cornerRadius: 20))
    }

    private struct Background: View {
        var body: some View {
            ZStack {
                LinearGradient(
                    colors: [
                        DesignSystemAsset.ctaGradientStart.swiftUIColor,
                        DesignSystemAsset.ctaGradientMid.swiftUIColor,
                        DesignSystemAsset.ctaGradientEnd.swiftUIColor,
                    ],
                    startPoint: UnitPoint(x: 0.2, y: 0),
                    endPoint: UnitPoint(x: 0.8, y: 1)
                )
                Circle()
                    .fill(DesignSystemAsset.ctaGlowTopLeft.swiftUIColor.opacity(0.55))
                    .frame(width: 130, height: 130)
                    .blur(radius: 30)
                    .offset(x: -100, y: -30)
                Circle()
                    .fill(DesignSystemAsset.ctaGlowBottomRight.swiftUIColor.opacity(0.65))
                    .frame(width: 130, height: 130)
                    .blur(radius: 28)
                    .offset(x: 100, y: 30)
                Circle()
                    .fill(DesignSystemAsset.ctaGlowTopCenter.swiftUIColor.opacity(0.30))
                    .frame(width: 100, height: 100)
                    .blur(radius: 22)
                    .offset(x: 0, y: -35)
            }
        }
    }

    private struct Content: View {
        var body: some View {
            HStack {
                Text("학습하러 가기")
                    .homeTypography(.ctaTitle)
                    .foregroundStyle(DesignSystemAsset.white.swiftUIColor)
                    .shadow(color: DesignSystemAsset.shadowSubtle.swiftUIColor.opacity(0.25), radius: 8, x: 0, y: 1)
                Spacer()
                PlayButton()
            }
        }
    }

    private struct PlayButton: View {
        var body: some View {
            ZStack {
                Circle()
                    .fill(DesignSystemAsset.white.swiftUIColor.opacity(0.16))
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay {
                        Circle().strokeBorder(DesignSystemAsset.white.swiftUIColor.opacity(0.3), lineWidth: 1)
                    }
                Image(systemName: "play.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(DesignSystemAsset.white.swiftUIColor)
            }
            .frame(width: 42, height: 42)
        }
    }
}
