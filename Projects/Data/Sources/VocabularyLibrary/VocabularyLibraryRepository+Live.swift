import Foundation

import DomainInterface
import NetworkingInterface

import Dependencies

private func fetchVocabularyLibraryFromNetwork() async throws -> VocabularyLibrary {
    @Dependency(\.authenticatedHTTPClient) var client
    let request = GetAllLevelsWithSessionsRequest()
    let dto: VocabularyLibraryResponseDTO = try await client.request(request)
    return dto.toDomain()
}

private func refreshVocabularyLibrary(store: VocabularyLibraryStore) async throws {
    let library = try await fetchVocabularyLibraryFromNetwork()
    await store.set(library)
}

extension VocabularyLibraryRepository: DependencyKey {
    public static let liveValue: VocabularyLibraryRepository = {
        let store = VocabularyLibraryStore()
        return VocabularyLibraryRepository(
            stream: {
                AsyncStream { continuation in
                    let id = UUID()
                    continuation.onTermination = { _ in
                        Task { await store.unregister(id: id) }
                    }
                    Task {
                        await store.register(id: id, continuation: continuation)
                        // 등록 직후, 마지막으로 한 번 최신 데이터를 가져온다 — 스트림엔 에러
                        // 채널이 없으므로 실패는 조용히 무시한다(캐시가 없으면 uiState는
                        // .loading에 머무른다).
                        try? await refreshVocabularyLibrary(store: store)
                    }
                }
            },
            refresh: {
                try await refreshVocabularyLibrary(store: store)
            }
        )
    }()
}
