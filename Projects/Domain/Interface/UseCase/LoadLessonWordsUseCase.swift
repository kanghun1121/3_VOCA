import Foundation

import Dependencies

/// 단어 목록 화면에 필요한 레슨을 조회하면서, 단어 상세 화면 진입 전 대기 시간을 줄이기 위해 그 레슨에
/// 속한 단어들의 상세 정보를 함께 prefetch하는 UseCase. `WordListViewModel` 전용이며, 단순
/// 조회만 필요한 다른 소비처(Domain API Explorer 등)는 `LessonRepository.fetchDetail`을 직접 쓴다.
/// `LoadLessonDetailUseCase`와 로직이 유사해 보이지만 prefetch 대상이 다르다 — 이쪽은 단어 상세를,
/// `LoadLessonDetailUseCase`는 오디오를 미리 받는다. 두 소비처의 필요가 달라 의도적으로 UseCase를
/// 나눴다.
public struct LoadLessonWordsUseCase: Sendable {
    public var execute: @Sendable (_ id: String) async throws -> Lesson

    public init(
        execute: @escaping @Sendable (_ id: String) async throws -> Lesson
    ) {
        self.execute = execute
    }
}

extension LoadLessonWordsUseCase: TestDependencyKey {
    public static let testValue = LoadLessonWordsUseCase(
        execute: unimplemented("\(Self.self).execute")
    )

    public static let previewValue = LoadLessonWordsUseCase(
        execute: { id in .preview(id: id) }
    )

    public static let previewLoading = LoadLessonWordsUseCase(
        execute: { _ in
            try await Task.sleep(for: .seconds(3600))
            throw CancellationError()
        }
    )
}

public extension DependencyValues {
    var loadLessonWordsUseCase: LoadLessonWordsUseCase {
        get { self[LoadLessonWordsUseCase.self] }
        set { self[LoadLessonWordsUseCase.self] = newValue }
    }
}
