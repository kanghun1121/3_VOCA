import DomainInterface

extension LevelSummary {
    var status: LevelStatus {
        if completedLessons == 0 {
            .notStarted
        } else if completedLessons >= totalLessons {
            .completed
        } else {
            .active
        }
    }

    var progressRatio: Double {
        totalLessons == 0 ? 0 : Double(completedLessons) / Double(totalLessons)
    }
}
