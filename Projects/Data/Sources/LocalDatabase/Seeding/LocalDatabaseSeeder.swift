import Foundation

enum LocalDatabaseSeederError: Error {
    case missingSeedResource(String)
}

/// 번들 시드 JSON 7개를 파싱해 각 도메인 LocalDataSource의 삽입 메서드로 나눠 전달하는
/// 오케스트레이션만 담당한다. "이미 시딩됐는지" 판단은 `LocalDatabaseSeeding`의 책임이고,
/// 실제 엔티티 삽입은 각 도메인 DataSource의 책임이다 — 이 타입은 그 둘 사이를 순서대로
/// 호출하고 마지막에 `context.save()`로 커밋할 뿐이다.
enum LocalDatabaseSeeder {
    static func seed(
        word: WordLocalDataSource,
        lesson: LessonLocalDataSource,
        level: LevelLocalDataSource,
        context: LocalDatabaseContext
    ) async throws {
        let levels: [LevelSeedDTO] = try decode("levels")
        let lessons: [LessonSeedDTO] = try decode("lessons")
        let lessonWords: [LessonWordSeedDTO] = try decode("lesson_words")
        let words: [WordSeedDTO] = try decode("words")
        let meanings: [WordMeaningSeedDTO] = try decode("word_meanings")
        let examples: [WordExampleSeedDTO] = try decode("word_examples")
        let distractors: [DistractorSeedDTO] = try decode("distractors")

        let distractorsByWordID = distractors.reduce(into: [Int: [String]]()) { result, item in
            result[item.wordID] = item.distractors
        }

        await level.insertLevels(levels.map {
            LevelEntity(id: $0.id, nameKo: $0.nameKo, cefrLabel: $0.cefrLabel, sortOrder: $0.sortOrder)
        })

        await lesson.insertLessons(lessons.map {
            LessonEntity(id: $0.id, levelID: $0.levelID, lessonNumber: $0.lessonNumber, wordCount: $0.wordCount)
        })

        await word.insertWords(words.map {
            WordEntity(
                id: $0.id,
                word: $0.word,
                levelID: $0.levelID,
                pronunciation: $0.pronunciation,
                audioUrl: $0.audioUrl,
                distractors: distractorsByWordID[$0.id] ?? []
            )
        })

        await word.insertMeanings(meanings.map {
            WordMeaningEntity(id: $0.id, wordID: $0.wordID, pos: $0.pos, ko: $0.ko, rank: $0.rank)
        })

        await word.insertExamples(examples.map {
            WordExampleEntity(
                id: $0.id,
                wordID: $0.wordID,
                order: $0.order,
                sentenceEn: $0.sentenceEn,
                sentenceKo: $0.sentenceKo,
                words: $0.words ?? [],
                chunks: $0.chunks ?? []
            )
        })

        await lesson.insertLessonWords(lessonWords.map {
            LessonWordEntity(lessonID: $0.lessonID, wordID: $0.wordID, position: $0.position)
        })

        // 전체를 한 번에 쌓고 마지막에 단 한 번만 저장한다 — 세 DataSource가 전부 같은
        // `LocalDatabaseContext`를 공유하므로(같은 ModelContext), 중간에 에러가 나면
        // 아무것도 커밋되지 않는다.
        try await context.save()
    }

    private static func decode<T: Decodable>(_ resourceName: String) throws -> [T] {
        guard let url = Bundle.module.url(forResource: resourceName, withExtension: "json") else {
            throw LocalDatabaseSeederError.missingSeedResource(resourceName)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([T].self, from: data)
    }
}
