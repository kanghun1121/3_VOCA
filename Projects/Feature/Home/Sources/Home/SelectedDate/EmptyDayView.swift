import SwiftUI

import DesignSystem

struct EmptyDayView: View {
    let isFuture: Bool
    let onGoToToday: () -> Void

    private var subtitle: String {
        isFuture ? "아직 오지 않은 날이에요" : "쉬어간 날도 기록의 일부예요"
    }

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(DesignSystemAsset.bgSubtle.swiftUIColor)
                    .frame(width: 44, height: 44)
                Circle()
                    .strokeBorder(
                        DesignSystemAsset.fgSubtle.swiftUIColor,
                        style: StrokeStyle(lineWidth: 3, dash: [3.5])
                    )
                    .frame(width: 20, height: 20)
            }
            VStack(spacing: 4) {
                Text("학습 기록이 없는 날이에요")
                    .homeTypography(.emptyDayTitle)
                    .foregroundStyle(DesignSystemAsset.fg.swiftUIColor)
                Text(subtitle)
                    .homeTypography(.emptyDaySubtext)
                    .foregroundStyle(DesignSystemAsset.fgSubtle.swiftUIColor)
            }
            if !isFuture {
                Button("오늘 학습으로 이동", action: onGoToToday)
                    .font(DesignSystemFontFamily.Pretendard.semiBold.swiftUIFont(size: 13))
                    .foregroundStyle(DesignSystemAsset.study300.swiftUIColor)
                    .padding(.vertical, 9)
                    .padding(.horizontal, 18)
                    .frame(minHeight: 44)
                    .overlay {
                        Capsule().strokeBorder(DesignSystemAsset.study300.swiftUIColor, lineWidth: 1)
                    }
            }
        }
        .padding(.top, 30)
        .frame(maxWidth: .infinity)
    }
}
