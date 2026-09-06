import Foundation

import Dependencies

/// 단어장 목록에 필요한 레슨을 조회하면서, 단어 상세 화면 진입 전 대기 시간을 줄이기 위해 그 레슨에
/// 속한 단어들의 상세 정보를 함께 prefetch하는 UseCase. `VocabularyListViewModel` 전용이며, 단순
/// 조회만 필요한 다른 소비처(Domain API Explorer 등)는 `LessonRepository.fetchDetail`을 직접 쓴다.
public struct LoadVocabularyListUseCase: Sendable {
    public var execute: @Sendable (_ id: String) async throws -> Lesson

    public init(
        execute: @escaping @Sendable (_ id: String) async throws -> Lesson
    ) {
        self.execute = execute
    }
}

extension LoadVocabularyListUseCase: TestDependencyKey {
    public static let testValue = LoadVocabularyListUseCase(
        execute: unimplemented("\(Self.self).execute")
    )

    public static let previewValue = LoadVocabularyListUseCase(
        execute: { id in .preview(id: id) }
    )

    public static let previewLoading = LoadVocabularyListUseCase(
        execute: { _ in
            try await Task.sleep(for: .seconds(3600))
            throw CancellationError()
        }
    )
}

public extension DependencyValues {
    var loadVocabularyListUseCase: LoadVocabularyListUseCase {
        get { self[LoadVocabularyListUseCase.self] }
        set { self[LoadVocabularyListUseCase.self] = newValue }
    }
}
