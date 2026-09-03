import SwiftUI

import DesignSystem

struct CalendarNavButtons: View {
    let isAtCurrentMonth: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onToday: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            if !isAtCurrentMonth {
                Button("오늘로", action: onToday)
                    .font(DesignSystemFontFamily.Pretendard.semiBold.swiftUIFont(size: 12))
                    .foregroundStyle(DesignSystemAsset.study300.swiftUIColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(DesignSystemAsset.study300.swiftUIColor.opacity(0.1))
                    .clipShape(.rect(cornerRadius: 8))
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            makeNavButton(
                label: "이전 달",
                systemImage: "chevron.left",
                action: onPrevious,
                isEnabled: true
            )
            makeNavButton(
                label: "다음 달",
                systemImage: "chevron.right",
                action: onNext,
                isEnabled: !isAtCurrentMonth
            )
        }
    }

    private func makeNavButton(
        label: String,
        systemImage: String,
        action: @escaping () -> Void,
        isEnabled: Bool
    ) -> some View {
        Button(label, systemImage: systemImage, action: action)
            .labelStyle(.iconOnly)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(
                isEnabled
                    ? DesignSystemAsset.fgMuted.swiftUIColor
                    : DesignSystemAsset.fgSubtle.swiftUIColor
            )
            .frame(width: 26, height: 26)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .disabled(!isEnabled)
    }
}
