import SwiftData

@Model
final class LessonEntity {
    @Attribute(.unique) var id: Int
    var levelID: Int
    var lessonNumber: Int
    var wordCount: Int

    init(id: Int, levelID: Int, lessonNumber: Int, wordCount: Int) {
        self.id = id
        self.levelID = levelID
        self.lessonNumber = lessonNumber
        self.wordCount = wordCount
    }
}
