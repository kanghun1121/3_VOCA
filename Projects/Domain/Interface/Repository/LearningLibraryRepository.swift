import Foundation

import Dependencies

/// `LearningLibrary`(및 관련 통계) 관련 API를 추상화한 포트. 실제 구현은 Data 모듈에서 제공한다.
public struct LearningLibraryRepository: Sendable {
    public var stream: @Sendable () -> AsyncStream<LearningLibrary>
    public var refresh: @Sendable () async throws -> Void

    public init(
        stream: @escaping @Sendable () -> AsyncStream<LearningLibrary>,
        refresh: @escaping @Sendable () async throws -> Void
    ) {
        self.stream = stream
        self.refresh = refresh
    }
}

extension LearningLibraryRepository: TestDependencyKey {
    public static let testValue = LearningLibraryRepository(
        stream: unimplemented("\(Self.self).stream"),
        refresh: unimplemented("\(Self.self).refresh")
    )

    public static let previewValue = LearningLibraryRepository(
        stream: {
            AsyncStream { continuation in
                continuation.yield(.previewFixture)
                continuation.finish()
            }
        },
        refresh: {}
    )
}

public extension DependencyValues {
    var learningLibraryRepository: LearningLibraryRepository {
        get { self[LearningLibraryRepository.self] }
        set { self[LearningLibraryRepository.self] = newValue }
    }
}
