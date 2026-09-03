import Foundation

import Dependencies

/// `VocabularyLibrary`(및 관련 통계) 관련 API를 추상화한 포트. 실제 구현은 Data 모듈에서 제공한다.
public struct VocabularyLibraryRepository: Sendable {
    public var stream: @Sendable () -> AsyncStream<VocabularyLibrary>
    public var refresh: @Sendable () async throws -> Void

    public init(
        stream: @escaping @Sendable () -> AsyncStream<VocabularyLibrary>,
        refresh: @escaping @Sendable () async throws -> Void
    ) {
        self.stream = stream
        self.refresh = refresh
    }
}

extension VocabularyLibraryRepository: TestDependencyKey {
    public static let testValue = VocabularyLibraryRepository(
        stream: unimplemented("\(Self.self).stream"),
        refresh: unimplemented("\(Self.self).refresh")
    )

    public static let previewValue = VocabularyLibraryRepository(
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
    var vocabularyLibraryRepository: VocabularyLibraryRepository {
        get { self[VocabularyLibraryRepository.self] }
        set { self[VocabularyLibraryRepository.self] = newValue }
    }
}
