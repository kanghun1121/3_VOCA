import Foundation

public enum LessonProgressStatus: String {
    case completed
    case notStarted = "not_started"
}

public struct LessonProgress: Equatable, Identifiable {
    public let id: String
    public let lessonNumber: Int
    public let totalWords: Int
    public let status: LessonProgressStatus
    public let lastStudiedAt: Date?
    public let accuracy: Double?
    public let wordsCompleted: Int

    public init(
        id: String,
        lessonNumber: Int,
        totalWords: Int,
        status: LessonProgressStatus,
        lastStudiedAt: Date?,
        accuracy: Double?,
        wordsCompleted: Int
    ) {
        self.id = id
        self.lessonNumber = lessonNumber
        self.totalWords = totalWords
        self.status = status
        self.lastStudiedAt = lastStudiedAt
        self.accuracy = accuracy
        self.wordsCompleted = wordsCompleted
    }
}

public struct LevelSummary: Equatable, Identifiable {
    public let id: String
    public let level: Int
    public let name: String
    public let difficulty: String
    public let totalLessons: Int
    public let completedLessons: Int
    public let lessons: [LessonProgress]

    public init(
        id: String,
        level: Int,
        name: String,
        difficulty: String,
        totalLessons: Int,
        completedLessons: Int,
        lessons: [LessonProgress]
    ) {
        self.id = id
        self.level = level
        self.name = name
        self.difficulty = difficulty
        self.totalLessons = totalLessons
        self.completedLessons = completedLessons
        self.lessons = lessons
    }
}

public struct LearningLibrary: Equatable {
    public let levels: [LevelSummary]

    public init(levels: [LevelSummary]) {
        self.levels = levels
    }
}

// MARK: - Preview Fixture

public extension LearningLibrary {
    static let previewFixture: LearningLibrary = {
        // "오늘" 기준 상대 날짜로 구성 — 실행 시점과 무관하게 항상 다양한 캘린더 케이스(당일 3건 캡 경계,
        // 다른 날 1건, 오늘은 0건)가 현재 달 화면에서 바로 보이도록 한다.
        let level1Completed = [
            LessonProgress(
                id: "1",
                lessonNumber: 1,
                totalWords: 20,
                status: .completed,
                lastStudiedAt: daysAgo(
                    5,
                    hour: 9,
                    minute: 20
                ),
                accuracy: 0.92,
                wordsCompleted: 20
            ),
            LessonProgress(
                id: "2",
                lessonNumber: 2,
                totalWords: 20,
                status: .completed,
                lastStudiedAt: daysAgo(
                    5,
                    hour: 14,
                    minute: 5
                ),
                accuracy: 0.87,
                wordsCompleted: 20
            ),
            LessonProgress(
                id: "3",
                lessonNumber: 3,
                totalWords: 20,
                status: .completed,
                lastStudiedAt: daysAgo(
                    5,
                    hour: 21,
                    minute: 40
                ),
                accuracy: 0.58,
                wordsCompleted: 20
            ),
            LessonProgress(
                id: "4",
                lessonNumber: 4,
                totalWords: 20,
                status: .completed,
                lastStudiedAt: daysAgo(
                    2,
                    hour: 19,
                    minute: 10
                ),
                accuracy: 0.88,
                wordsCompleted: 20
            ),
        ]
        let level1Lessons = level1Completed + (5...42).map { i in
            LessonProgress(
                id: "\(i)",
                lessonNumber: i,
                totalWords: i == 42 ? 5 : 20,
                status: .notStarted,
                lastStudiedAt: nil,
                accuracy: nil,
                wordsCompleted: 0
            )
        }

        return LearningLibrary(levels: [
            LevelSummary(
                id: "level_1",
                level: 1,
                name: "씨앗",
                difficulty: "A1",
                totalLessons: 42,
                completedLessons: 4,
                lessons: level1Lessons
            ),
            LevelSummary(
                id: "level_2",
                level: 2,
                name: "새싹",
                difficulty: "A2",
                totalLessons: 39,
                completedLessons: 0,
                lessons: (1...39).map { i in
                    LessonProgress(
                        id: "\(42 + i)",
                        lessonNumber: i,
                        totalWords: i == 39 ? 12 : 20,
                        status: .notStarted,
                        lastStudiedAt: nil,
                        accuracy: nil,
                        wordsCompleted: 0
                    )
                }
            ),
            LevelSummary(
                id: "level_3",
                level: 3,
                name: "줄기",
                difficulty: "B1",
                totalLessons: 99,
                completedLessons: 0,
                lessons: (1...99).map { i in
                    LessonProgress(
                        id: "\(81 + i)",
                        lessonNumber: i,
                        totalWords: i == 99 ? 7 : 20,
                        status: .notStarted,
                        lastStudiedAt: nil,
                        accuracy: nil,
                        wordsCompleted: 0
                    )
                }
            ),
            LevelSummary(
                id: "level_4",
                level: 4,
                name: "가지",
                difficulty: "B2",
                totalLessons: 64,
                completedLessons: 0,
                lessons: (1...64).map { i in
                    LessonProgress(
                        id: "\(180 + i)",
                        lessonNumber: i,
                        totalWords: i == 64 ? 11 : 20,
                        status: .notStarted,
                        lastStudiedAt: nil,
                        accuracy: nil,
                        wordsCompleted: 0
                    )
                }
            ),
            LevelSummary(
                id: "level_5",
                level: 5,
                name: "꽃",
                difficulty: "C1",
                totalLessons: 50,
                completedLessons: 0,
                lessons: (1...50).map { i in
                    LessonProgress(
                        id: "\(244 + i)",
                        lessonNumber: i,
                        totalWords: i == 50 ? 15 : 20,
                        status: .notStarted,
                        lastStudiedAt: nil,
                        accuracy: nil,
                        wordsCompleted: 0
                    )
                }
            ),
            LevelSummary(
                id: "level_6",
                level: 6,
                name: "나무",
                difficulty: "C2",
                totalLessons: 30,
                completedLessons: 0,
                lessons: (1...30).map { i in
                    LessonProgress(
                        id: "\(294 + i)",
                        lessonNumber: i,
                        totalWords: i == 30 ? 18 : 20,
                        status: .notStarted,
                        lastStudiedAt: nil,
                        accuracy: nil,
                        wordsCompleted: 0
                    )
                }
            ),
        ])
    }()

    private static func daysAgo(
        _ days: Int,
        hour: Int,
        minute: Int
    ) -> Date {
        let calendar = Calendar.current
        let base = calendar.date(byAdding: .day, value: -days, to: .now) ?? .now
        return calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: base
        ) ?? base
    }
}
