import Foundation

import Dependencies

/// 세션 상세를 조회하면서, 게임/단어장 진입 전 대기 시간을 줄이기 위해 그 세션의
/// 오디오 prefetch를 함께 트리거하는 UseCase. `LessonDetailViewModel`/`WordGameViewModel`
/// 전용이며, 단순 조회만 필요한 다른 소비처는 `LessonRepository.fetchDetail`을 직접 쓴다.
public struct LoadLessonDetailUseCase: Sendable {
    public var execute: @Sendable (_ id: String) async throws -> (lesson: Lesson, audioReady: Task<Void, Never>)

    public init(
        execute: @escaping @Sendable (_ id: String) async throws -> (lesson: Lesson, audioReady: Task<Void, Never>)
    ) {
        self.execute = execute
    }
}

extension LoadLessonDetailUseCase: TestDependencyKey {
    public static let testValue = LoadLessonDetailUseCase(
        execute: unimplemented("\(Self.self).execute")
    )
}

public extension DependencyValues {
    var loadLessonDetailUseCase: LoadLessonDetailUseCase {
        get { self[LoadLessonDetailUseCase.self] }
        set { self[LoadLessonDetailUseCase.self] = newValue }
    }
}
