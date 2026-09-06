import Foundation

import Dependencies

/// 레슨별 학습 이력(완료 기록) 조회/구독 및 완료 처리 API를 추상화한 포트. 실제 구현은 Data 모듈에서 제공한다.
public struct LearningHistoryRepository: Sendable {
    public var stream: @Sendable (_ lessonID: String) -> AsyncStream<LearningHistory>
    public var complete: @Sendable (_ lessonID: Int) async throws -> Void

    public init(
        stream: @escaping @Sendable (_ lessonID: String) -> AsyncStream<LearningHistory>,
        complete: @escaping @Sendable (_ lessonID: Int) async throws -> Void
    ) {
        self.stream = stream
        self.complete = complete
    }
}

extension LearningHistoryRepository: TestDependencyKey {
    public static let testValue = LearningHistoryRepository(
        stream: unimplemented("\(Self.self).stream"),
        complete: unimplemented("\(Self.self).complete")
    )
}

public extension DependencyValues {
    var learningHistoryRepository: LearningHistoryRepository {
        get { self[LearningHistoryRepository.self] }
        set { self[LearningHistoryRepository.self] = newValue }
    }
}
