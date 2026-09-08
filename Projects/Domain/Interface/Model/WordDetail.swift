import Foundation

public struct WordDetail: Equatable {
    public struct Definition: Equatable {
        public let meaning: String
        public let partOfSpeech: PartOfSpeech

        public init(meaning: String, partOfSpeech: PartOfSpeech) {
            self.meaning = meaning
            self.partOfSpeech = partOfSpeech
        }
    }

    public struct Example: Equatable {
        public struct WordAnnotation: Equatable {
            public let word: String
            public let meaning: String
            public let pos: String

            public init(
                word: String,
                meaning: String,
                pos: String
            ) {
                self.word = word
                self.meaning = meaning
                self.pos = pos
            }
        }

        public struct Chunk: Equatable {
            public let text: String
            public let meaning: String

            public init(text: String, meaning: String) {
                self.text = text
                self.meaning = meaning
            }
        }

        public let en: String
        public let ko: String
        public let order: Int
        public let words: [WordAnnotation]?
        public let chunks: [Chunk]?

        public init(
            en: String,
            ko: String,
            order: Int,
            words: [WordAnnotation]? = nil,
            chunks: [Chunk]? = nil
        ) {
            self.en = en
            self.ko = ko
            self.order = order
            self.words = words
            self.chunks = chunks
        }
    }

    public let id: String
    public let term: String
    public let level: Int
    public let pronunciation: String
    public let definitions: [Definition]
    public let examples: [Example]

    public init(
        id: String,
        term: String,
        level: Int,
        pronunciation: String,
        definitions: [Definition],
        examples: [Example]
    ) {
        self.id = id
        self.term = term
        self.level = level
        self.pronunciation = pronunciation
        self.definitions = definitions
        self.examples = examples
    }
}

// MARK: - Preview Fixture

public extension WordDetail {
    static let previewFixture = WordDetail(
        id: "word_766",
        term: "dark",
        level: 1,
        pronunciation: "/dɑːrk/",
        definitions: [
            Definition(meaning: "어두운", partOfSpeech: .adjective),
            Definition(meaning: "어둠", partOfSpeech: .noun)
        ],
        examples: [
            Example(
                en: "The room is very dark. Please turn on the light.",
                ko: "방이 매우 어두워. 불 좀 켜줘.",
                order: 1
            ),
            Example(
                en: "She was afraid of the dark when she was little.",
                ko: "그녀는 어렸을 때 어둠을 무서워했어.",
                order: 2
            )
        ]
    )
}
