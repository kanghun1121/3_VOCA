import SwiftUI

import DesignSystem

struct WordGameLoadingView: View {
    var body: some View {
        ZStack {
            GameBackground()
            WordGameLoadingContent()
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - 콘텐츠

private struct WordGameLoadingContent: View {
    var body: some View {
        ZStack {
            HStack(spacing: 14) {
                WordGamePulseDot(delay: 0)
                WordGamePulseDot(delay: 0.2)
                WordGamePulseDot(delay: 0.4)
            }

            VStack {
                Spacer()
                WordGameLoadingCaption()
                    .padding(.bottom, 128)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("오늘의 단어를 준비하고 있어요")
        .accessibilityAddTraits(.updatesFrequently)
    }
}

// MARK: - 캡션

private struct WordGameLoadingCaption: View {
    @ScaledMetric private var mainSize: CGFloat = 18
    @ScaledMetric private var subSize: CGFloat = 14

    var body: some View {
        VStack(spacing: 7) {
            Text("오늘의 단어를 준비하고 있어요")
                .font(DesignSystemFontFamily.Pretendard.bold.swiftUIFont(size: mainSize))
                .foregroundStyle(DesignSystemAsset.white.swiftUIColor)
                .kerning(-0.01 * 18)

            Text("잠시만 기다려 주세요")
                .font(DesignSystemFontFamily.Pretendard.medium.swiftUIFont(size: subSize))
                .foregroundStyle(DesignSystemAsset.white.swiftUIColor.opacity(0.5))
        }
        .multilineTextAlignment(.center)
    }
}

// MARK: - 점 펄스

// 1.4s 사이클(0.7s 상승 + 0.7s 하강), 점별 딜레이로 좌→우 파동 연출
// delay: 핸드오프 스태거 0s / 0.2s / 0.4s
private struct WordGamePulseDot: View {
    let delay: Double

    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Circle()
            .frame(width: 15, height: 15)
            .foregroundStyle(DesignSystemAsset.white.swiftUIColor)
            .scaleEffect(reduceMotion ? 0.8 : (isAnimating ? 1.0 : 0.6))
            .opacity(reduceMotion ? 0.68 : (isAnimating ? 1.0 : 0.35))
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(
                    .easeInOut(duration: 0.7)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    isAnimating = true
                }
            }
    }
}
