import Foundation

import Dependencies

/// 세션을 완료 처리하는 UseCase. ViewModel은 Repository가 아닌 이 UseCase를 통해서만 호출한다.
public struct CompleteSessionUseCase: Sendable {
    public var execute: @Sendable (_ sessionID: Int) async throws -> Void

    public init(execute: @escaping @Sendable (_ sessionID: Int) async throws -> Void) {
        self.execute = execute
    }
}

extension CompleteSessionUseCase: TestDependencyKey {
    public static let testValue = CompleteSessionUseCase(
        execute: unimplemented("\(Self.self).execute")
    )

    public static let previewValue = CompleteSessionUseCase(
        execute: { _ in }
    )
}

public extension DependencyValues {
    var completeSessionUseCase: CompleteSessionUseCase {
        get { self[CompleteSessionUseCase.self] }
        set { self[CompleteSessionUseCase.self] = newValue }
    }
}
