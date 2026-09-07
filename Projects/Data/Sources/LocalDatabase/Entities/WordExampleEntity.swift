import SwiftData

/// word_examples.json의 words/chunks는 그 예문 안에서만 의미 있는 부속 데이터라
/// 별도 @Model이 아니라 Codable 값 타입 배열 속성으로 저장한다.
struct ExampleWordPayload: Codable {
    let word: String
    let pos: String
    let meaning: String
}

struct ExampleChunkPayload: Codable {
    let text: String
    let meaning: String
}

@Model
final class WordExampleEntity {
    @Attribute(.unique) var id: Int
    var wordID: Int
    var order: Int
    var sentenceEn: String
    var sentenceKo: String
    var words: [ExampleWordPayload]
    var chunks: [ExampleChunkPayload]

    init(
        id: Int,
        wordID: Int,
        order: Int,
        sentenceEn: String,
        sentenceKo: String,
        words: [ExampleWordPayload],
        chunks: [ExampleChunkPayload]
    ) {
        self.id = id
        self.wordID = wordID
        self.order = order
        self.sentenceEn = sentenceEn
        self.sentenceKo = sentenceKo
        self.words = words
        self.chunks = chunks
    }
}
