import XCTest

@testable import Data

final class LevelLocalDataSourceTests: XCTestCase {
    func test_allLevels는_삽입_순서와_무관하게_sortOrder_오름차순으로_반환된다() async throws {
        let db = LocalDatabaseTestContext()
        try await db.seed(
            LevelEntity(id: 2, nameKo: "새싹", cefrLabel: "A2", sortOrder: 2),
            LevelEntity(id: 1, nameKo: "씨앗", cefrLabel: "A1", sortOrder: 1)
        )

        let levels = try await db.run {
            try await LevelLocalDataSource().allLevels()
        }

        XCTAssertEqual(levels.map(\.nameKo), ["씨앗", "새싹"])
    }

    func test_존재하지_않는_레벨_id를_조회하면_nil을_반환한다() async throws {
        let db = LocalDatabaseTestContext()

        let result = try await db.run {
            try await LevelLocalDataSource().level(id: 999)
        }

        XCTAssertNil(result)
    }
}
