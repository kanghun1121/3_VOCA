import Foundation

extension Calendar {
    /// 현재 달(offset 0)을 상한으로 월 오프셋을 이동시킨다. 미래 달로는 이동하지 않는다.
    func homeMonthOffset(_ offset: Int, movedBy delta: Int) -> Int {
        min(offset + delta, 0)
    }

    /// 오늘 기준 `offset`만큼 이동한 표시 월의 대표 날짜.
    func homeDisplayedMonth(today: Date, offset: Int) -> Date {
        date(byAdding: .month, value: offset, to: today) ?? today
    }

    /// "2026년 8월" 형태의 헤더 타이틀.
    func homeMonthTitle(for date: Date) -> String {
        let year = component(.year, from: date)
        let month = component(.month, from: date)
        return "\(String(year))년 \(String(month))월"
    }

    /// 표시 월의 캘린더 그리드를 주 단위(7칸)로 조립한다.
    func homeCalendarRows(
        displayedMonth: Date,
        today: Date,
        selectedDate: Date,
        recordsByDate: [Date: [DayRecord]]
    ) -> [[CalendarDay]] {
        let period = monthlyCalendarPeriod(for: displayedMonth)
        let days = homeCalendarDays(
            for: period,
            displayedMonth: displayedMonth,
            today: today,
            selectedDate: selectedDate,
            recordsByDate: recordsByDate
        )
        return stride(from: 0, to: days.count, by: 7).map { start in
            Array(days[start..<min(start + 7, days.count)])
        }
    }

    private func homeCalendarDays(
        for period: DateInterval,
        displayedMonth: Date,
        today: Date,
        selectedDate: Date,
        recordsByDate: [Date: [DayRecord]]
    ) -> [CalendarDay] {
        let displayedComps = dateComponents([.year, .month], from: displayedMonth)
        var days: [CalendarDay] = []
        var current = period.start
        while current < period.end {
            let comps = dateComponents([.year, .month], from: current)
            let isCurrentMonth = comps.year == displayedComps.year && comps.month == displayedComps.month
            let dayStart = startOfDay(for: current)
            let recordCount = recordsByDate[dayStart]?.count ?? 0
            days.append(CalendarDay(
                date: current,
                dayNumber: component(.day, from: current),
                isCurrentMonth: isCurrentMonth,
                isToday: isDate(current, inSameDayAs: today),
                isFuture: dayStart > today,
                isSelected: isDate(current, inSameDayAs: selectedDate),
                dotCount: min(recordCount, CalendarDayCellKind.maxDotCount)
            ))
            guard let next = date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return days
    }
}
