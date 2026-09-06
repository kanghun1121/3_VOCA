import DomainInterface

extension SessionDetailResponseDTO {
    func toDomain() -> Session {
        Session(
            id: session.id,
            level: session.level,
            sessionNumber: session.sessionNumber,
            estimatedDurationMinutes: session.estimatedMinutes,
            cefrLevel: session.difficulty,
            words: words.map { $0.toDomain() },
            record: learningHistory?.toDomain()
        )
    }
}

private extension SessionDetailResponseDTO.Word {
    func toDomain() -> Session.Word {
        Session.Word(
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
    func toDomain() -> Session.Word.Definition {
        Session.Word.Definition(
            id: id,
            partOfSpeech: PartOfSpeech(rawValue: partOfSpeech) ?? .unknown,
            meaning: meaning
        )
    }
}

private extension SessionDetailResponseDTO.LearningHistory {
    func toDomain() -> Session.Record {
        Session.Record(
            firstCompletedAt: firstCompletedAt,
            studyCount: studyCount
        )
    }
}
