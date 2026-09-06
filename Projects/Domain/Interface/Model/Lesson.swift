public struct Session: Equatable {
    public struct Word: Equatable, Identifiable {
        public struct Definition: Equatable, Identifiable {
            public let id: String
            public let partOfSpeech: PartOfSpeech
            public let meaning: String

            public init(
                id: String,
                partOfSpeech: PartOfSpeech,
                meaning: String
            ) {
                self.id = id
                self.partOfSpeech = partOfSpeech
                self.meaning = meaning
            }
        }

        public let id: String
        public let term: String
        public let pronunciation: String
        public let definitions: [Definition]
        public let distractors: [String]
        public let audioUrl: String

        public init(
            id: String,
            term: String,
            pronunciation: String,
            definitions: [Definition],
            distractors: [String],
            audioUrl: String
        ) {
            self.id = id
            self.term = term
            self.pronunciation = pronunciation
            self.definitions = definitions
            self.distractors = distractors
            self.audioUrl = audioUrl
        }
    }

    public struct Record: Equatable {
        public let firstCompletedAt: String
        public let studyCount: Int

        public init(
            firstCompletedAt: String,
            studyCount: Int
        ) {
            self.firstCompletedAt = firstCompletedAt
            self.studyCount = studyCount
        }
    }

    public let id: String
    public let level: Int
    public let sessionNumber: Int
    public let estimatedDurationMinutes: Int
    public let cefrLevel: String
    public let words: [Word]
    public let record: Record?

    public init(
        id: String,
        level: Int,
        sessionNumber: Int,
        estimatedDurationMinutes: Int,
        cefrLevel: String,
        words: [Word],
        record: Record?
    ) {
        self.id = id
        self.level = level
        self.sessionNumber = sessionNumber
        self.estimatedDurationMinutes = estimatedDurationMinutes
        self.cefrLevel = cefrLevel
        self.words = words
        self.record = record
    }
}

// MARK: - Preview Fixtures

public extension Session {
    static func previewWithRecord(id: String) -> Session {
        Session(
            id: id,
            level: 1,
            sessionNumber: 2,
            estimatedDurationMinutes: 15,
            cefrLevel: "A1-A2",
            words: previewWords,
            record: Record(
                firstCompletedAt: "2026.05.01",
                studyCount: 3
            )
        )
    }

    static func previewWithoutRecord(id: String) -> Session {
        Session(
            id: id,
            level: 1,
            sessionNumber: 2,
            estimatedDurationMinutes: 15,
            cefrLevel: "A1-A2",
            words: previewWords,
            record: nil
        )
    }

    static let previewWords: [Word] = [
        Word(
            id: "word_001",
            term: "ambiguous",
            pronunciation: "/æmˈbɪɡjuəs/",
            definitions: [
                Word.Definition(id: "def_001_1", partOfSpeech: .adjective, meaning: "모호한, 애매한")
            ],
            distractors: [],
            audioUrl: ""
        ),
        Word(
            id: "word_002",
            term: "persevere",
            pronunciation: "/ˌpɜːrsəˈvɪr/",
            definitions: [
                Word.Definition(id: "def_002_1", partOfSpeech: .verb, meaning: "끈기 있게 계속하다, 인내하다")
            ],
            distractors: [],
            audioUrl: ""
        ),
        Word(
            id: "word_003",
            term: "eloquent",
            pronunciation: "/ˈeləkwənt/",
            definitions: [
                Word.Definition(id: "def_003_1", partOfSpeech: .adjective, meaning: "유창한, 능변의")
            ],
            distractors: [],
            audioUrl: ""
        ),
        Word(
            id: "word_004",
            term: "inevitable",
            pronunciation: "/ɪnˈevɪtəbl/",
            definitions: [
                Word.Definition(id: "def_004_1", partOfSpeech: .adjective, meaning: "불가피한, 필연적인"),
                Word.Definition(id: "def_004_2", partOfSpeech: .noun, meaning: "피할 수 없는 일"),
            ],
            distractors: [],
            audioUrl: ""
        ),
        Word(
            id: "word_005",
            term: "meticulous",
            pronunciation: "/məˈtɪkjuləs/",
            definitions: [
                Word.Definition(id: "def_005_1", partOfSpeech: .adjective, meaning: "꼼꼼한, 세심한")
            ],
            distractors: [],
            audioUrl: ""
        ),
        Word(
            id: "word_006",
            term: "benevolent",
            pronunciation: "/bəˈnevələnt/",
            definitions: [
                Word.Definition(id: "def_006_1", partOfSpeech: .adjective, meaning: "자비로운, 친절한")
            ],
            distractors: [],
            audioUrl: ""
        ),
        Word(
            id: "word_007",
            term: "ephemeral",
            pronunciation: "/ɪˈfemərəl/",
            definitions: [
                Word.Definition(id: "def_007_1", partOfSpeech: .adjective, meaning: "덧없는, 단명하는")
            ],
            distractors: [],
            audioUrl: ""
        ),
        Word(
            id: "word_008",
            term: "resilient",
            pronunciation: "/rɪˈzɪliənt/",
            definitions: [
                Word.Definition(id: "def_008_1", partOfSpeech: .adjective, meaning: "회복력 있는, 탄력적인")
            ],
            distractors: [],
            audioUrl: ""
        ),
        Word(
            id: "word_009",
            term: "tenacious",
            pronunciation: "/təˈneɪʃəs/",
            definitions: [
                Word.Definition(id: "def_009_1", partOfSpeech: .adjective, meaning: "끈질긴, 고집스러운")
            ],
            distractors: [],
            audioUrl: ""
        ),
        Word(
            id: "word_010",
            term: "serene",
            pronunciation: "/səˈriːn/",
            definitions: [
                Word.Definition(id: "def_010_1", partOfSpeech: .adjective, meaning: "고요한, 평온한")
            ],
            distractors: [],
            audioUrl: ""
        ),
        Word(
            id: "word_011",
            term: "arduous",
            pronunciation: "/ˈɑːrdjuəs/",
            definitions: [
                Word.Definition(id: "def_011_1", partOfSpeech: .adjective, meaning: "힘든, 고된")
            ],
            distractors: [],
            audioUrl: ""
        ),
        Word(
            id: "word_012",
            term: "pragmatic",
            pronunciation: "/præɡˈmætɪk/",
            definitions: [
                Word.Definition(id: "def_012_1", partOfSpeech: .adjective, meaning: "실용적인, 현실적인")
            ],
            distractors: [],
            audioUrl: ""
        ),
        Word(
            id: "word_013",
            term: "vivid",
            pronunciation: "/ˈvɪvɪd/",
            definitions: [
                Word.Definition(id: "def_013_1", partOfSpeech: .adjective, meaning: "생생한, 선명한")
            ],
            distractors: [],
            audioUrl: ""
        ),
        Word(
            id: "word_014",
            term: "profound",
            pronunciation: "/prəˈfaʊnd/",
            definitions: [
                Word.Definition(id: "def_014_1", partOfSpeech: .adjective, meaning: "심오한, 깊은")
            ],
            distractors: [],
            audioUrl: ""
        ),
        Word(
            id: "word_015",
            term: "subtle",
            pronunciation: "/ˈsʌtl/",
            definitions: [
                Word.Definition(id: "def_015_1", partOfSpeech: .adjective, meaning: "미묘한, 섬세한")
            ],
            distractors: [],
            audioUrl: ""
        ),
    ]

}
