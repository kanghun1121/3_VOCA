import SwiftUI

struct CalendarWeekRow: View {
    let days: [CalendarDay]
    let onDateTapped: (Date) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(days, id: \.date) { day in
                let kind = resolveCellKind(for: day)
                Button {
                    onDateTapped(day.date)
                } label: {
                    CalendarDayCell(kind: kind)
                }
                .buttonStyle(.plain)
                .disabled(!isTappable(day))
            }
        }
    }

    private func isTappable(_ day: CalendarDay) -> Bool {
        day.isCurrentMonth && !day.isFuture
    }

    private func resolveCellKind(for day: CalendarDay) -> CalendarDayCellKind {
        guard day.isCurrentMonth else { return .empty }
        if day.isSelected { return .selected(day: day.dayNumber, dotCount: day.dotCount) }
        if day.isToday { return .today(day: day.dayNumber, dotCount: day.dotCount) }
        if day.isFuture { return .future(day: day.dayNumber) }
        return .past(day: day.dayNumber, dotCount: day.dotCount)
    }
}
