import Foundation

import Dependencies

/// 세션 상세를 조회하는 UseCase. ViewModel은 Repository가 아닌 이 UseCase를 통해서만 호출한다.
public struct GetSessionDetailUseCase: Sendable {
    public var execute: @Sendable (_ id: String) async throws -> Session

    public init(execute: @escaping @Sendable (_ id: String) async throws -> Session) {
        self.execute = execute
    }
}

extension GetSessionDetailUseCase: TestDependencyKey {
    public static let testValue = GetSessionDetailUseCase(
        execute: unimplemented("\(Self.self).execute")
    )

    public static let previewValue = GetSessionDetailUseCase(
        execute: { id in .previewWithRecord(id: id) }
    )

    public static let previewLoading = GetSessionDetailUseCase(
        execute: { _ in
            try await Task.sleep(for: .seconds(3600))
            throw CancellationError()
        }
    )
}

public extension DependencyValues {
    var getSessionDetailUseCase: GetSessionDetailUseCase {
        get { self[GetSessionDetailUseCase.self] }
        set { self[GetSessionDetailUseCase.self] = newValue }
    }
}
