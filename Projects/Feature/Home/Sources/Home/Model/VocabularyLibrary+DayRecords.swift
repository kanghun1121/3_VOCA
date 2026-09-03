import Foundation

import DomainInterface

extension VocabularyLibrary {
    /// 완료된 세션을 마지막 학습 날짜(로컬 자정 기준)별로 그룹핑한다.
    /// 재학습한 세션은 가장 최근 학습 날짜에만 나타난다 (lastStudiedAt이 단일 값이기 때문).
    func dayRecords(calendar: Calendar = .current) -> [Date: [DayRecord]] {
        var grouped: [Date: [DayRecord]] = [:]
        for level in levels {
            for session in level.sessions {
                guard session.status == .completed, let lastStudiedAt = session.lastStudiedAt else { continue }
                let day = calendar.startOfDay(for: lastStudiedAt)
                let record = DayRecord(
                    id: session.id,
                    sessionID: session.id,
                    time: lastStudiedAt,
                    title: "\(level.name) \(session.sessionNumber)번째 세션",
                    wordCount: session.totalWords
                )
                grouped[day, default: []].append(record)
            }
        }
        for key in grouped.keys {
            grouped[key]?.sort { $0.time < $1.time }
        }
        return grouped
    }
}
