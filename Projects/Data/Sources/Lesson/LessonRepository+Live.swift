import Foundation

import DomainInterface
import NetworkingInterface

import Dependencies

private actor SessionCache {
    private var store: [String: Session] = [:]

    func fetch(_ id: String) -> Session? {
        store[id]
    }

    func set(_ id: String, _ session: Session) {
        store[id] = session
    }

    func invalidate(_ id: String) {
        store.removeValue(forKey: id)
    }
}

extension SessionRepository: DependencyKey {
    public static let liveValue: SessionRepository = {
        @Dependency(\.authenticatedHTTPClient) var http
        let cache = SessionCache()
        return SessionRepository(
            fetchSessionDetail: { id in
                if let cached = await cache.fetch(id) { return cached }
                let request = GetSessionDetailRequest(sessionID: id)
                let dto: SessionDetailResponseDTO = try await http.request(request)
                let session = dto.toDomain()
                await cache.set(id, session)
                return session
            },
            completeSession: { sessionID in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
                let localDate = formatter.string(from: Date())
                let request = CompleteSessionRequest(sessionID: sessionID, localDate: localDate)
                let _: CompleteSessionResponseDTO = try await http.request(request)
                await cache.invalidate(String(sessionID))
            }
        )
    }()
}
