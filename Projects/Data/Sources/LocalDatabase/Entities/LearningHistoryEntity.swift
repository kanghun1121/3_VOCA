import Foundation
import SwiftData

@Model
final class LearningHistoryEntity {
    @Attribute(.unique) var lessonID: Int
    var firstCompletedAt: Date
    var lastStudiedAt: Date
    var studyCount: Int

    init(lessonID: Int, firstCompletedAt: Date, lastStudiedAt: Date, studyCount: Int) {
        self.lessonID = lessonID
        self.firstCompletedAt = firstCompletedAt
        self.lastStudiedAt = lastStudiedAt
        self.studyCount = studyCount
    }
}
