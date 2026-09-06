import DomainInterface

extension SessionHistoryResponseDTO {
    func toDomain() -> LearningHistory {
        LearningHistory(
            firstCompletedAt: firstCompletedAt,
            studyCount: studyCount
        )
    }
}
