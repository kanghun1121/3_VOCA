import DomainInterface

extension SessionDetailResponseDTO {
    func toDomain() -> Lesson {
        Lesson(
            id: session.id,
            level: session.level,
            lessonNumber: session.sessionNumber,
            estimatedDurationMinutes: session.estimatedMinutes,
            cefrLevel: session.difficulty,
            words: words.map { $0.toDomain() }
        )
    }
}

private extension SessionDetailResponseDTO.Word {
    func toDomain() -> Lesson.Word {
        Lesson.Word(
            id: id,
            term: term,
            pronunciation: pronunciation,
            definitions: definitions.map { $0.toDomain() },
            distractors: distractors,
            audioUrl: audioUrl
        )
    }
}

private extension SessionDetailResponseDTO.Word.Definition {
    func toDomain() -> Lesson.Word.Definition {
        Lesson.Word.Definition(
            id: id,
            partOfSpeech: PartOfSpeech(rawValue: partOfSpeech) ?? .unknown,
            meaning: meaning
        )
    }
}
