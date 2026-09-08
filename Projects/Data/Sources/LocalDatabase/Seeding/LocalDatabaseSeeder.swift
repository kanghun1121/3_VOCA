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
        // rank 오름차순으로 정렬해서 저장한다 — 조회 시(Entities+Mapping.swift)도 다시 정렬하지만,
        // 시더가 정렬을 빠뜨리는 회귀를 막는 이중 방어.
        let meaningsByWordID = Dictionary(grouping: meanings, by: \.wordID)
            .mapValues { rows in
                rows.sorted { $0.rank < $1.rank }.map {
                    WordMeaningPayload(id: $0.id, pos: $0.pos, ko: $0.ko, rank: $0.rank)
                }
            }
        // position 오름차순으로 정렬해서 저장한다 — 배열 인덱스가 곧 정렬 결과이므로 여기서
        // 한 번만 정렬하면 이후 조회에서 다시 정렬할 필요가 없다.
        let wordIDsByLessonID = Dictionary(grouping: lessonWords, by: \.lessonID)
            .mapValues { rows in rows.sorted { $0.position < $1.position }.map(\.wordID) }

        await level.insertLevels(levels.map {
            LevelEntity(id: $0.id, nameKo: $0.nameKo, cefrLabel: $0.cefrLabel, sortOrder: $0.sortOrder)
        })

        await lesson.insertLessons(lessons.map {
            LessonEntity(
                id: $0.id,
                levelID: $0.levelID,
                lessonNumber: $0.lessonNumber,
                orderedWordIDs: wordIDsByLessonID[$0.id] ?? []
            )
        })

        await word.insertWords(words.map {
            WordEntity(
                id: $0.id,
                word: $0.word,
                levelID: $0.levelID,
                pronunciation: $0.pronunciation,
                audioUrl: $0.audioUrl,
                distractors: distractorsByWordID[$0.id] ?? [],
                meanings: meaningsByWordID[$0.id] ?? []
            )
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
