import Foundation

public struct LessonCompletionRecord: Equatable, Identifiable {
    public let lessonID: String
    public let levelName: String
    public let lessonNumber: Int
    public let totalWords: Int
    public let lastStudiedAt: Date

    public var id: String { lessonID }

    public init(
        lessonID: String,
        levelName: String,
        lessonNumber: Int,
        totalWords: Int,
        lastStudiedAt: Date
    ) {
        self.lessonID = lessonID
        self.levelName = levelName
        self.lessonNumber = lessonNumber
        self.totalWords = totalWords
        self.lastStudiedAt = lastStudiedAt
    }
}

// MARK: - Preview Fixture

public extension LessonCompletionRecord {
    static let previewFixture = LessonCompletionRecord(
        lessonID: "1",
        levelName: "Level 1",
        lessonNumber: 1,
        totalWords: 10,
        lastStudiedAt: .now
    )
}
