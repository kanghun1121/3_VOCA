import SwiftUI

struct MonthlyCalendarCard: View {
    let viewModel: HomeViewModel

    @State private var monthOffset = 0

    private var cal: Calendar { .current }

    private var displayedMonth: Date {
        cal.homeDisplayedMonth(today: viewModel.today, offset: monthOffset)
    }

    private var rows: [[CalendarDay]] {
        cal.homeCalendarRows(
            displayedMonth: displayedMonth,
            today: viewModel.today,
            selectedDate: viewModel.selectedDate,
            recordsByDate: viewModel.dayRecordsByDate
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CalendarHeaderRow(
                title: cal.homeMonthTitle(for: displayedMonth),
                isAtCurrentMonth: monthOffset == 0,
                onPrevious: previousMonth,
                onNext: nextMonth,
                onToday: { monthOffset = 0 }
            )
            .padding(.bottom, 16)
            CalendarWeekdayHeader()
                .padding(.bottom, 6)
            CalendarGridSection(rows: rows) { date in
                viewModel.didTapDate(date)
            }
            .contentShape(Rectangle())
            .simultaneousGesture(monthSwipeGesture)
        }
        .padding(.horizontal, 14)
        .onChange(of: viewModel.selectedDate) { _, newValue in
            if cal.isDate(newValue, inSameDayAs: viewModel.today) {
                monthOffset = 0
            }
        }
    }

    private func previousMonth() {
        monthOffset = cal.homeMonthOffset(monthOffset, movedBy: -1)
    }

    private func nextMonth() {
        monthOffset = cal.homeMonthOffset(monthOffset, movedBy: 1)
    }

    private var monthSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 24)
            .onEnded { value in
                let horizontal = value.translation.width
                let vertical = value.translation.height
                guard abs(horizontal) > abs(vertical) else { return }
                withAnimation(.easeInOut(duration: 0.2)) {
                    if horizontal < 0 {
                        nextMonth()
                    } else {
                        previousMonth()
                    }
                }
            }
    }
}
