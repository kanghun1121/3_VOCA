import SwiftUI

import DesignSystem

struct LessonCell: View {
    let lessonNumber: Int
    let status: LessonCellStatus

    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(backgroundColor)
            .aspectRatio(1, contentMode: .fit)
            .overlay { icon }
    }

    private var backgroundColor: Color {
        switch status {
        case .done: DesignSystemAsset.progressActive.swiftUIColor
        case .current, .todo: DesignSystemAsset.lockBg.swiftUIColor
        }
    }

    @ViewBuilder
    private var icon: some View {
        switch status {
        case .done:
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(DesignSystemAsset.white.swiftUIColor)
                .accessibilityHidden(true)
        case .current, .todo:
            Text("\(lessonNumber)")
                .font(DesignSystemFontFamily.Pretendard.extraBold.swiftUIFont(size: 12))
                .foregroundStyle(DesignSystemAsset.lock.swiftUIColor)
                .monospacedDigit()
        }
    }
}
