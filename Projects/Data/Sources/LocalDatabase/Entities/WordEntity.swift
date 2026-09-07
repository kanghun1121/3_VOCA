import SwiftData

@Model
final class WordEntity {
    @Attribute(.unique) var id: Int
    var word: String
    var levelID: Int
    var pronunciation: String
    var audioUrl: String
    /// distractors.json은 단어당 정확히 1행(1:1)이라 별도 엔티티 대신 속성으로 흡수한다.
    var distractors: [String]

    init(
        id: Int,
        word: String,
        levelID: Int,
        pronunciation: String,
        audioUrl: String,
        distractors: [String]
    ) {
        self.id = id
        self.word = word
        self.levelID = levelID
        self.pronunciation = pronunciation
        self.audioUrl = audioUrl
        self.distractors = distractors
    }
}
