import Foundation

import Dependencies

/// 단어 상세 조회 API를 추상화한 포트. 실제 구현은 Data 모듈에서 제공한다.
public struct WordRepository: Sendable {
    public var fetchDetail: @Sendable (_ id: String) async throws -> WordDetail
    public var prefetchDetails: @Sendable (_ ids: [String]) async -> Void

    public init(
        fetchDetail: @escaping @Sendable (_ id: String) async throws -> WordDetail,
        prefetchDetails: @escaping @Sendable (_ ids: [String]) async -> Void
    ) {
        self.fetchDetail = fetchDetail
        self.prefetchDetails = prefetchDetails
    }
}

extension WordRepository: TestDependencyKey {
    public static let testValue = WordRepository(
        fetchDetail: unimplemented("\(Self.self).fetchDetail"),
        prefetchDetails: unimplemented("\(Self.self).prefetchDetails", placeholder: ())
    )
}

public extension DependencyValues {
    var wordRepository: WordRepository {
        get { self[WordRepository.self] }
        set { self[WordRepository.self] = newValue }
    }
}
