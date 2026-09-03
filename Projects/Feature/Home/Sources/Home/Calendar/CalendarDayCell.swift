import SwiftUI

import DesignSystem

struct CalendarDayCell: View {
    let kind: CalendarDayCellKind

    var body: some View {
        VStack(spacing: 4) {
            NumberCircle(kind: kind)
            DotsRow(kind: kind)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 46)
    }

    private struct NumberCircle: View {
        let kind: CalendarDayCellKind

        var body: some View {
            switch kind {
            case .empty:
                Color.clear.frame(width: 30, height: 30)

            case .future(let day):
                NumberLabel(day: day, color: DesignSystemAsset.fgSubtle.swiftUIColor, emphasized: false)

            case .past(let day, _):
                NumberLabel(day: day, color: DesignSystemAsset.fgStrong.swiftUIColor, emphasized: false)

            case .today(let day, _):
                NumberLabel(day: day, color: DesignSystemAsset.fgStrong.swiftUIColor, emphasized: true)

            case .selected(let day, _):
                Circle()
                    .fill(DesignSystemAsset.study300.swiftUIColor)
                    .frame(width: 30, height: 30)
                    .overlay {
                        NumberLabel(day: day, color: DesignSystemAsset.white.swiftUIColor, emphasized: true)
                    }
            }
        }
    }

    private struct DotsRow: View {
        let kind: CalendarDayCellKind

        private var dotCount: Int {
            switch kind {
            case .empty, .future: 0
            case .past(_, let count), .today(_, let count), .selected(_, let count): count
            }
        }

        private var dotColor: Color {
            switch kind {
            case .selected: DesignSystemAsset.study300.swiftUIColor
            default: DesignSystemAsset.study300.swiftUIColor.opacity(0.30)
            }
        }

        var body: some View {
            HStack(spacing: 2.5) {
                ForEach(0..<dotCount, id: \.self) { _ in
                    Circle()
                        .fill(dotColor)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(height: 4)
        }
    }

    private struct NumberLabel: View {
        let day: Int
        let color: Color
        let emphasized: Bool

        var body: some View {
            Text("\(day)")
                .homeTypography(emphasized ? .dateNumberEmphasis : .dateNumber)
                .foregroundStyle(color)
                .monospacedDigit()
                .frame(width: 30, height: 30)
        }
    }
}
