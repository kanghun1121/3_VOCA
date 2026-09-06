import Foundation

import DomainInterface

extension VocabularyLibraryResponseDTO {
    func toDomain() -> VocabularyLibrary {
        VocabularyLibrary(levels: levels.map { $0.toDomain() })
    }
}

private extension VocabularyLibraryResponseDTO.LevelDTO {
    func toDomain() -> LevelSummary {
        LevelSummary(
            id: id,
            level: level,
            name: name,
            difficulty: difficulty,
            totalLessons: totalSessions,
            completedLessons: completedSessions,
            lessons: sessions.map { $0.toDomain() }
        )
    }
}

private extension VocabularyLibraryResponseDTO.SessionDTO {
    func toDomain() -> LessonProgress {
        LessonProgress(
            id: String(id),
            lessonNumber: sessionNumber,
            totalWords: totalWords,
            status: LessonProgressStatus(rawValue: status) ?? .notStarted,
            lastStudiedAt: lastStudiedAt.flatMap { Self.iso.date(from: $0) },
            accuracy: accuracy,
            wordsCompleted: wordsCompleted ?? 0
        )
    }

    private static let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
}
