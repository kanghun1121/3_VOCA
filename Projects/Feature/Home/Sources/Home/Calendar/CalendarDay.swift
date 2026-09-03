import Foundation

struct CalendarDay: Equatable {
    let date: Date
    let dayNumber: Int
    let isCurrentMonth: Bool
    let isToday: Bool
    let isFuture: Bool
    let isSelected: Bool
    let dotCount: Int
}
