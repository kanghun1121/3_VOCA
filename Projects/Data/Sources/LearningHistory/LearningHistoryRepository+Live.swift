import Foundation

import DomainInterface
import NetworkingInterface

import Dependencies

extension LearningHistoryRepository: DependencyKey {
    public static let liveValue: LearningHistoryRepository = {
        @Dependency(\.authenticatedHTTPClient) var http
        let store = LearningHistoryStore()

        return LearningHistoryRepository(
            stream: { lessonID in
                AsyncStream { continuation in
                    let subscriberID = UUID()
                    continuation.onTermination = { _ in
                        Task { await store.unregister(id: lessonID, subscriberID: subscriberID) }
                    }
                    Task {
                        await store.register(id: lessonID, subscriberID: subscriberID, continuation: continuation)
                        // 등록 직후, 마지막으로 한 번 최신 데이터를 가져온다 — 스트림엔 에러
                        // 채널이 없으므로 실패는 조용히 무시한다(아직 완료 이력이 없는 경우도
                        // 이 경로로 흡수되어 learningHistory는 nil로 남는다).
                        let request = GetSessionHistoryRequest(sessionID: lessonID)
                        guard let dto = try? await http.request(request) as SessionHistoryResponseDTO else { return }
                        await store.set(id: lessonID, dto.toDomain())
                    }
                }
            },
            complete: { lessonID in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
                let localDate = formatter.string(from: Date())
                let request = CompleteSessionRequest(sessionID: lessonID, localDate: localDate)
                let _: CompleteSessionResponseDTO = try await http.request(request)
                // 완료 처리 자체는 이미 성공했으므로, 구독자에게 갱신값을 밀어주기 위한
                // 재조회가 실패해도(try?) 전체를 실패시키지 않는다 — 화면은 다음 정상
                // 갱신(재진입 등) 때까지 잠시 stale할 뿐이다.
                let refreshRequest = GetSessionHistoryRequest(sessionID: String(lessonID))
                if let refreshedDTO = try? await http.request(refreshRequest) as SessionHistoryResponseDTO {
                    await store.set(id: String(lessonID), refreshedDTO.toDomain())
                }
            }
        )
    }()
}
