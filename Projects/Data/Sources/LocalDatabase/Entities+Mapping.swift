import Foundation

import DomainInterface

// MARK: - WordDetail

extension WordEntity {
    /// `meanings`는 rank 오름차순으로 정렬해서 사용한다(대표 뜻 결정 로직이 첫 번째 요소에
    /// 의존하므로 저장 순서를 신뢰하지 않고 매핑 경계에서 항상 명시적으로 정렬한다).
    /// `examples`는 order 오름차순으로 정렬되어 들어온다고 가정한다(정렬은
    /// `WordLocalDataSource`의 조회 메서드 책임).
    func toWordDetail(examples: [WordExampleEntity]) -> WordDetail {
        WordDetail(
            id: String(id),
            term: word,
            level: levelID,
            pronunciation: pronunciation,
            definitions: meanings.sorted { $0.rank < $1.rank }.map { $0.toWordDetailDefinition() },
            examples: examples.map { $0.toWordDetailExample() }
        )
    }
}

extension WordMeaningPayload {
    func toWordDetailDefinition() -> WordDetail.Definition {
        WordDetail.Definition(
            meaning: ko,
            partOfSpeech: PartOfSpeech(rawValue: pos) ?? .unknown
        )
    }
}

extension WordExampleEntity {
    func toWordDetailExample() -> WordDetail.Example {
        WordDetail.Example(
            en: sentenceEn,
            ko: sentenceKo,
            order: order,
            words: words.isEmpty ? nil : words.map {
                WordDetail.Example.WordAnnotation(word: $0.word, meaning: $0.meaning, pos: $0.pos)
            },
            chunks: chunks.isEmpty ? nil : chunks.map {
                WordDetail.Example.Chunk(text: $0.text, meaning: $0.meaning)
            }
        )
    }
}

// MARK: - Lesson (레슨 상세 — 단어 목록 포함)

extension LessonEntity {
    /// `words`는 lesson_words의 position 오름차순으로 정렬되어 들어온다고 가정한다.
    func toLesson(cefrLabel: String, words: [Lesson.Word]) -> Lesson {
        Lesson(
            id: String(id),
            level: levelID,
            lessonNumber: lessonNumber,
            cefrLevel: cefrLabel,
            words: words
        )
    }
}

extension WordEntity {
    /// `meanings`는 rank 오름차순으로 정렬해서 사용한다(위 `toWordDetail`과 동일한 이유).
    func toLessonWord() -> Lesson.Word {
        Lesson.Word(
            id: String(id),
            term: word,
            pronunciation: pronunciation,
            definitions: meanings.sorted { $0.rank < $1.rank }.map { $0.toLessonWordDefinition() },
            distractors: distractors,
            audioUrl: audioUrl
        )
    }
}

extension WordMeaningPayload {
    func toLessonWordDefinition() -> Lesson.Word.Definition {
        Lesson.Word.Definition(
            id: String(id),
            partOfSpeech: PartOfSpeech(rawValue: pos) ?? .unknown,
            meaning: ko
        )
    }
}

// MARK: - LearningLibrary 정적 스켈레톤 (진행 상태는 LearningLibraryRepository+Live.swift의
// liveValue 안에서 로컬 완료 이력(LearningHistoryEntity)으로 병합)

extension LevelEntity {
    /// `lessons`는 lessonNumber 오름차순으로 정렬되어 들어온다고 가정한다. 진행 상태 필드는
    /// 전부 "시작 전" 기본값이며, 원격 진행 상태와의 병합은 이 타입의 책임이 아니다.
    func toStaticSummary(lessons: [LessonEntity]) -> LevelSummary {
        LevelSummary(
            id: String(id),
            level: id,
            name: nameKo,
            difficulty: cefrLabel,
            totalLessons: lessons.count,
            completedLessons: 0,
            lessons: lessons.map { $0.toStaticProgress() }
        )
    }
}

extension LessonEntity {
    func toStaticProgress() -> LessonProgress {
        LessonProgress(
            id: String(id),
            lessonNumber: lessonNumber,
            totalWords: orderedWordIDs.count,
            status: .notStarted,
            lastStudiedAt: nil,
            accuracy: nil,
            wordsCompleted: 0
        )
    }
}
