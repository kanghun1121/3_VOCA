import Foundation

import DomainInterface
import NetworkingInterface

import Dependencies

extension LessonRepository: DependencyKey {
    public static let liveValue: LessonRepository = {
        @Dependency(\.authenticatedHTTPClient) var http
        let store = LessonStore()

        return LessonRepository(
            fetchDetail: { id in
                if let cached = await store.fetch(id) { return cached }
                let request = GetSessionDetailRequest(sessionID: id)
                let dto: SessionDetailResponseDTO = try await http.request(request)
                let lesson = dto.toDomain()
                await store.set(id, lesson)
                return lesson
            }
        )
    }()
}
