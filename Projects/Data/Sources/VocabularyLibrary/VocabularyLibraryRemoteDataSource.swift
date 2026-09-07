import Foundation

import NetworkingInterface

import Dependencies

/// 유저별 학습 진행 상태(완료 레슨, 정확도 등)를 원격에서 가져오는 계층. 응답에 정적 필드
/// (레벨 이름/레슨 번호 등)도 함께 오지만, 그건 이제 로컬 시드가 정본이라 Repository가
/// 병합 시점에 버린다(`VocabularyLibraryMerge` 참고).
struct VocabularyLibraryRemoteDataSource: Sendable {
    func fetchLibrary() async throws -> VocabularyLibraryResponseDTO {
        @Dependency(\.authenticatedHTTPClient) var client
        return try await client.request(GetAllLevelsWithSessionsRequest())
    }
}

extension VocabularyLibraryRemoteDataSource: DependencyKey {
    static let liveValue = VocabularyLibraryRemoteDataSource()
}

extension VocabularyLibraryRemoteDataSource: TestDependencyKey {
    static let testValue = VocabularyLibraryRemoteDataSource()
}

extension DependencyValues {
    var vocabularyLibraryRemoteDataSource: VocabularyLibraryRemoteDataSource {
        get { self[VocabularyLibraryRemoteDataSource.self] }
        set { self[VocabularyLibraryRemoteDataSource.self] = newValue }
    }
}
