import Foundation

import Dependencies

/// 세션 상세 조회/완료 API를 추상화한 포트. 실제 구현은 Data 모듈에서 제공한다.
public struct SessionRepository: Sendable {
    public var fetchSessionDetail: @Sendable (_ id: String) async throws -> Session
    public var completeSession: @Sendable (_ sessionID: Int) async throws -> Void

    public init(
        fetchSessionDetail: @escaping @Sendable (_ id: String) async throws -> Session,
        completeSession: @escaping @Sendable (_ sessionID: Int) async throws -> Void
    ) {
        self.fetchSessionDetail = fetchSessionDetail
        self.completeSession = completeSession
    }
}

extension SessionRepository: TestDependencyKey {
    public static let testValue = SessionRepository(
        fetchSessionDetail: unimplemented("\(Self.self).fetchSessionDetail"),
        completeSession: unimplemented("\(Self.self).completeSession")
    )
}

public extension DependencyValues {
    var sessionRepository: SessionRepository {
        get { self[SessionRepository.self] }
        set { self[SessionRepository.self] = newValue }
    }
}
