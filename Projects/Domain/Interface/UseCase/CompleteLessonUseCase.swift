import Foundation

import Dependencies

/// 레슨 완료를 기록하면서, 그 결과로 파생되는 다른 화면의 캐시(학습 라이브러리 진행률)도 함께
/// 무효화하는 UseCase. `WordGameViewModel` 전용 — `LearningHistoryRepository.complete`만 직접
/// 호출하면 완료 이력은 반영되지만 `VocabularyLibraryRepository`가 들고 있는 진행률 캐시는
/// 갱신되지 않는다(서로 다른 Repository/Store라 자동으로 연동되지 않음). 이 조합 책임을
/// Data 계층(Repository-Live)이 아니라 Domain UseCase에 둬서, Repository가 Repository를
/// 의존하는 관계를 만들지 않는다.
public struct CompleteLessonUseCase: Sendable {
    public var execute: @Sendable (_ lessonID: Int) async throws -> Void

    public init(
        execute: @escaping @Sendable (_ lessonID: Int) async throws -> Void
    ) {
        self.execute = execute
    }
}

extension CompleteLessonUseCase: TestDependencyKey {
    public static let testValue = CompleteLessonUseCase(
        execute: unimplemented("\(Self.self).execute")
    )

    public static let previewValue = CompleteLessonUseCase(
        execute: { _ in }
    )
}

public extension DependencyValues {
    var completeLessonUseCase: CompleteLessonUseCase {
        get { self[CompleteLessonUseCase.self] }
        set { self[CompleteLessonUseCase.self] = newValue }
    }
}
