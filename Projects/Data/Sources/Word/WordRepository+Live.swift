import Foundation

import DomainInterface
import NetworkingInterface

import Dependencies

extension WordRepository: DependencyKey {
    public static let liveValue: WordRepository = {
        @Dependency(\.authenticatedHTTPClient) var http
        let cache = WordDetailCache()
        return WordRepository(
            fetchDetail: { id in
                if let cached = await cache.get(id) { return cached }
                let request = GetWordDetailRequest(wordID: id)
                let dto: WordDetailResponseDTO = try await http.request(request)
                let detail = dto.toDomain()
                await cache.set(id, detail)
                return detail
            },
            prefetchDetails: { ids in
                await withTaskGroup(of: Void.self) { group in
                    for id in ids {
                        group.addTask {
                            guard await cache.get(id) == nil else { return }
                            guard let dto: WordDetailResponseDTO = try? await http.request(
                                GetWordDetailRequest(wordID: id)
                            ) else { return }
                            await cache.set(id, dto.toDomain())
                        }
                    }
                }
            }
        )
    }()
}
