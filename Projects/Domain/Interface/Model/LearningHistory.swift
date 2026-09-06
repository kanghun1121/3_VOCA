public struct LearningHistory: Equatable {
    public let firstCompletedAt: String
    public let studyCount: Int

    public init(
        firstCompletedAt: String,
        studyCount: Int
    ) {
        self.firstCompletedAt = firstCompletedAt
        self.studyCount = studyCount
    }
}

// MARK: - Preview Fixtures

public extension LearningHistory {
    static let preview = LearningHistory(
        firstCompletedAt: "2026.05.01",
        studyCount: 3
    )
}
