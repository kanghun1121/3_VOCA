import Foundation

import DomainInterface

import Dependencies

extension WordRepository: DependencyKey {
    public static let liveValue = WordRepository(
        fetchDetail: { id in
            @Dependency(\.wordLocalDataSource) var wordLocalDataSource
            return try await wordLocalDataSource.wordDetail(id: numericID(from: id))
        },
        prefetchDetails: { _ in
            // 로컬 DB 조회는 네트워크 왕복이 없어 "미리 당겨오기"가 더 이상 의미가 없다.
        }
    )
}

// "word_766" → 766, "766" → 766
private func numericID(from id: String) throws -> Int {
    guard let value = Int(id.components(separatedBy: "_").last ?? id) else {
        throw LocalDatabaseError.invalidWordID(id)
    }
    return value
}
