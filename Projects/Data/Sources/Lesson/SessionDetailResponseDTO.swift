import Foundation

struct SessionDetailResponseDTO: Decodable {
    struct Metadata: Decodable {
        let id: String
        let level: Int
        let sessionNumber: Int
        let title: String
        let wordCount: Int
        let estimatedMinutes: Int
        let difficulty: String
    }

    struct Word: Decodable {
        struct Definition: Decodable {
            let id: String
            let partOfSpeech: String
            let meaning: String
        }

        let id: String
        let term: String
        let pronunciation: String
        let definitions: [Definition]
        let distractors: [String]
        let audioUrl: String
    }

    let session: Metadata
    let words: [Word]
}
