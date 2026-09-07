import SwiftData
import XCTest

import Dependencies
@testable import Data

final class LevelLocalDataSourceTests: XCTestCase {
    private func makeContext() -> LocalDatabaseContext {
        LocalDatabaseContext(modelContainer: LocalDatabaseSchema.makeInMemoryContainer())
    }

    func test_allLevels는_삽입_순서와_무관하게_sortOrder_오름차순으로_반환된다() async throws {
        let context = makeContext()
        await context.insert(LevelEntity(id: 2, nameKo: "새싹", cefrLabel: "A2", sortOrder: 2))
        await context.insert(LevelEntity(id: 1, nameKo: "씨앗", cefrLabel: "A1", sortOrder: 1))
        try await context.save()

        let levels = try await withDependencies {
            $0.localDatabaseContext = context
        } operation: {
            try await LevelLocalDataSource().allLevels()
        }

        XCTAssertEqual(levels.map(\.nameKo), ["씨앗", "새싹"])
    }

    func test_존재하지_않는_레벨_id를_조회하면_nil을_반환한다() async throws {
        let context = makeContext()

        let result = try await withDependencies {
            $0.localDatabaseContext = context
        } operation: {
            try await LevelLocalDataSource().level(id: 999)
        }

        XCTAssertNil(result)
    }
}
