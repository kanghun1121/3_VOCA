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
            totalSessions: totalSessions,
            completedSessions: completedSessions,
            sessions: sessions.map { $0.toDomain() }
        )
    }
}

private extension VocabularyLibraryResponseDTO.SessionDTO {
    func toDomain() -> SessionProgress {
        SessionProgress(
            id: String(id),
            sessionNumber: sessionNumber,
            totalWords: totalWords,
            status: SessionProgressStatus(rawValue: status) ?? .notStarted,
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
