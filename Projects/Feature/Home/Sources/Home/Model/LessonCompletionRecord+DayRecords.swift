import Foundation

import DomainInterface

extension [LessonCompletionRecord] {
    /// 완료된 레슨을 마지막 학습 날짜(로컬 자정 기준)별로 그룹핑한다.
    /// 재학습한 레슨은 가장 최근 학습 날짜에만 나타난다 (lastStudiedAt이 단일 값이기 때문).
    func dayRecords(calendar: Calendar = .current) -> [Date: [DayRecord]] {
        var grouped: [Date: [DayRecord]] = [:]
        for record in self {
            let day = calendar.startOfDay(for: record.lastStudiedAt)
            let dayRecord = DayRecord(
                id: record.lessonID,
                lessonID: record.lessonID,
                time: record.lastStudiedAt,
                title: "\(record.levelName) \(record.lessonNumber)번째 레슨",
                wordCount: record.totalWords
            )
            grouped[day, default: []].append(dayRecord)
        }
        for key in grouped.keys {
            grouped[key]?.sort { $0.time < $1.time }
        }
        return grouped
    }
}
