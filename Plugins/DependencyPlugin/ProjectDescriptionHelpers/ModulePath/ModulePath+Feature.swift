import ProjectDescription

public extension ModulePath {
    enum Feature: String, CaseIterable {
        case chunkReader = "ChunkReader"
        case chatBot = "ChatBot"
        case home = "Home"
        case login = "Login"
        case lesson = "Lesson"
        case word = "Word"
        case wordGame = "WordGame"
        case myPage = "MyPage"

        public static let name = "Feature"
    }
}
