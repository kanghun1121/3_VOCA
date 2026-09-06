import Foundation

import Dependencies

/// 레슨 콘텐츠(단어 목록 등) 조회 API를 추상화한 포트. 실제 구현은 Data 모듈에서 제공한다.
public struct LessonRepository: Sendable {
    public var fetchDetail: @Sendable (_ id: String) async throws -> Lesson

    public init(
        fetchDetail: @escaping @Sendable (_ id: String) async throws -> Lesson
    ) {
        self.fetchDetail = fetchDetail
    }
}

extension LessonRepository: TestDependencyKey {
    public static let testValue = LessonRepository(
        fetchDetail: unimplemented("\(Self.self).fetchDetail")
    )
}

public extension DependencyValues {
    var lessonRepository: LessonRepository {
        get { self[LessonRepository.self] }
        set { self[LessonRepository.self] = newValue }
    }
}
