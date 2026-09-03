import Foundation

struct VocabularyLibraryResponseDTO: Decodable {
    let levels: [LevelDTO]

    struct LevelDTO: Decodable {
        let id: String
        let level: Int
        let name: String
        let difficulty: String
        let totalSessions: Int
        let completedSessions: Int
        let sessions: [SessionDTO]
    }

    struct SessionDTO: Decodable {
        let id: Int
        let sessionNumber: Int
        let totalWords: Int
        let status: String
        let lastStudiedAt: String?
        let accuracy: Double?
        let wordsCompleted: Int?
    }
}
