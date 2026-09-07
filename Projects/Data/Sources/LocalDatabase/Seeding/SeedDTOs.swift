import Foundation

/// 번들 시드 JSON 7개와 1:1 대응하는 디코딩 스키마. 도메인 매핑에서 쓰지 않는 필드
/// (primary_pos/all_pos/cefr/note/description 등)는 의도적으로 선언하지 않는다 —
/// Decodable은 선언 안 된 키를 자동으로 무시하므로 파싱에는 영향 없다.

struct LevelSeedDTO: Decodable {
    let id: Int
    let nameKo: String
    let cefrLabel: String
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id
        case nameKo = "name_ko"
        case cefrLabel = "cefr_label"
        case sortOrder = "sort_order"
    }
}

struct LessonSeedDTO: Decodable {
    let id: Int
    let levelID: Int
    let lessonNumber: Int
    let wordCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case levelID = "level_id"
        case lessonNumber = "lesson_number"
        case wordCount = "word_count"
    }
}

struct LessonWordSeedDTO: Decodable {
    let lessonID: Int
    let wordID: Int
    let position: Int

    enum CodingKeys: String, CodingKey {
        case lessonID = "lesson_id"
        case wordID = "word_id"
        case position
    }
}

struct WordSeedDTO: Decodable {
    let id: Int
    let word: String
    let levelID: Int
    let pronunciation: String
    let audioUrl: String

    enum CodingKeys: String, CodingKey {
        case id
        case word
        case levelID = "level_id"
        case pronunciation
        case audioUrl = "audio_url"
    }
}

struct WordMeaningSeedDTO: Decodable {
    let id: Int
    let wordID: Int
    let pos: String
    let ko: String
    let rank: Int

    enum CodingKeys: String, CodingKey {
        case id
        case wordID = "word_id"
        case pos
        case ko
        case rank
    }
}

struct WordExampleSeedDTO: Decodable {
    let id: Int
    let wordID: Int
    let order: Int
    let sentenceEn: String
    let sentenceKo: String
    let words: [ExampleWordPayload]?
    let chunks: [ExampleChunkPayload]?

    enum CodingKeys: String, CodingKey {
        case id
        case wordID = "word_id"
        case order
        case sentenceEn = "sentence_en"
        case sentenceKo = "sentence_ko"
        case words
        case chunks
    }
}

struct DistractorSeedDTO: Decodable {
    let wordID: Int
    let distractors: [String]

    enum CodingKeys: String, CodingKey {
        case wordID = "word_id"
        case distractors
    }
}
