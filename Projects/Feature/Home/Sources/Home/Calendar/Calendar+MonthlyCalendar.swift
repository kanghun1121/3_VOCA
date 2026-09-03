import Foundation

extension Calendar {
    /// 월간 캘린더 표시 기간 계산 (이전/다음 달 일수 포함, 월요일 시작 기준)
    func monthlyCalendarPeriod(for date: Date) -> DateInterval {
        guard let monthInterval = dateInterval(of: .month, for: date),
              let firstWeekday = dateComponents([.weekday], from: monthInterval.start).weekday
        else {
            return DateInterval(start: date, end: date)
        }

        let leadingCount = (firstWeekday - 2 + 7) % 7
        let startDate = self.date(byAdding: .day, value: -leadingCount, to: monthInterval.start)
            ?? monthInterval.start

        let daysFromStartToMonthEnd = dateComponents([.day], from: startDate, to: monthInterval.end).day ?? 0
        let remainder = daysFromStartToMonthEnd % 7
        var trailingCount = remainder > 0 ? 7 - remainder : 0

        // 4주(28칸)로 딱 떨어지는 경우 5주로 확장해 행 수 일관성 유지
        if daysFromStartToMonthEnd == 28 {
            trailingCount += 7
        }

        let endDate = self.date(byAdding: .day, value: trailingCount, to: monthInterval.end)
            ?? monthInterval.end

        return DateInterval(start: startDate, end: endDate)
    }
}
