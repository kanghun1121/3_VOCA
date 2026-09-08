import SwiftUI

import DesignSystem

// 1.25s 사이클(0.625s 상승 + 0.625s 하강), 점별 딜레이로 좌→우 파동 연출
// delay: 핸드오프 스태거 0s / 0.18s / 0.36s
struct PulseDot: View {
    let delay: Double

    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Circle()
            .frame(width: 12, height: 12)
            .foregroundStyle(DesignSystemAsset.growDeep.swiftUIColor)
            .scaleEffect(reduceMotion ? 0.62 : (isAnimating ? 1.0 : 0.62))
            .opacity(reduceMotion ? 0.55 : (isAnimating ? 1.0 : 0.28))
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(
                    .easeInOut(duration: 0.625)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    isAnimating = true
                }
            }
    }
}
