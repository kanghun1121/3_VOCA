import DomainInterface

extension LevelSummary {
    var status: LevelStatus {
        if completedSessions == 0 {
            .notStarted
        } else if completedSessions >= totalSessions {
            .completed
        } else {
            .active
        }
    }

    var progressRatio: Double {
        totalSessions == 0 ? 0 : Double(completedSessions) / Double(totalSessions)
    }
}
