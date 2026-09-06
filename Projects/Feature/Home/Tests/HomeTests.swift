import XCTest

@testable import FeatureHome

final class CalendarGridTests: XCTestCase {

    private let cal = Calendar.current

    func test_현재달에서_다음달로의_이동은_차단된다() {
        XCTAssertEqual(cal.homeMonthOffset(0, movedBy: 1), 0, "현재 달에서 미래 달로의 이동이 차단되어야 합니다.")
    }

    func test_이전달_이동_후_다시_다음달로_이동하면_현재달로_돌아온다() {
        let previous = cal.homeMonthOffset(0, movedBy: -1)
        XCTAssertEqual(previous, -1)
        XCTAssertEqual(cal.homeMonthOffset(previous, movedBy: 1), 0)
    }

    func test_이전달_이동시_월_타이틀이_이전달로_표시된다() {
        let june = cal.date(from: DateComponents(
            year: 2026,
            month: 6,
            day: 1
        ))!
        let displayed = cal.homeDisplayedMonth(today: june, offset: -1)

        XCTAssertEqual(cal.homeMonthTitle(for: displayed), "2026년 5월")
    }

    func test_캘린더_그리드는_7칸_단위의_행으로_구성된다() {
        let june = cal.date(from: DateComponents(
            year: 2026,
            month: 6,
            day: 1
        ))!
        let rows = cal.homeCalendarRows(
            displayedMonth: june,
            today: june,
            selectedDate: june,
            recordsByDate: [:]
        )

        XCTAssertGreaterThanOrEqual(rows.count, 5)
        XCTAssertTrue(rows.allSatisfy { $0.count == 7 })
    }

    func test_기록이_최대치를_넘으면_점_개수가_캡을_초과하지_않는다() {
        let june = cal.date(from: DateComponents(
            year: 2026,
            month: 6,
            day: 15
        ))!
        let dayStart = cal.startOfDay(for: june)
        let records = (0..<4).map { index in
            DayRecord(
                id: "\(index)",
                lessonID: "\(index)",
                time: june,
                title: "세션",
                wordCount: 10
            )
        }

        let rows = cal.homeCalendarRows(
            displayedMonth: june,
            today: june,
            selectedDate: june,
            recordsByDate: [dayStart: records]
        )

        let target = rows.flatMap { $0 }.first { $0.isCurrentMonth && cal.isDate($0.date, inSameDayAs: june) }
        XCTAssertEqual(target?.dotCount, CalendarDayCellKind.maxDotCount)
    }

    func test_선택된_날짜만_isSelected가_true다() {
        let june = cal.date(from: DateComponents(
            year: 2026,
            month: 6,
            day: 1
        ))!
        let selected = cal.date(from: DateComponents(
            year: 2026,
            month: 6,
            day: 10
        ))!
        let rows = cal.homeCalendarRows(
            displayedMonth: june,
            today: june,
            selectedDate: selected,
            recordsByDate: [:]
        )

        let selectedDays = rows.flatMap { $0 }.filter(\.isSelected)
        XCTAssertEqual(selectedDays.count, 1)
        XCTAssertEqual(selectedDays.first?.dayNumber, 10)
    }
}
