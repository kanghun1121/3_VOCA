import Foundation

import NetworkingInterface

import Dependencies

struct LearningHistoryRemoteDataSource: Sendable {
    func sessionHistory(sessionID: String) async throws -> SessionHistoryResponseDTO {
        @Dependency(\.authenticatedHTTPClient) var http
        return try await http.request(GetSessionHistoryRequest(sessionID: sessionID))
    }

    func completeSession(sessionID: Int, localDate: String) async throws {
        @Dependency(\.authenticatedHTTPClient) var http
        let _: CompleteSessionResponseDTO = try await http.request(CompleteSessionRequest(sessionID: sessionID, localDate: localDate))
    }
}

extension LearningHistoryRemoteDataSource: DependencyKey {
    static let liveValue = LearningHistoryRemoteDataSource()
}

extension LearningHistoryRemoteDataSource: TestDependencyKey {
    static let testValue = LearningHistoryRemoteDataSource()
}

extension DependencyValues {
    var learningHistoryRemoteDataSource: LearningHistoryRemoteDataSource {
        get { self[LearningHistoryRemoteDataSource.self] }
        set { self[LearningHistoryRemoteDataSource.self] = newValue }
    }
}
