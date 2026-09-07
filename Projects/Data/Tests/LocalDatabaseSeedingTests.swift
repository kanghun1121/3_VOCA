import SwiftData
import XCTest

import Dependencies
@testable import Data

final class LocalDatabaseSeedingTests: XCTestCase {
    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: LocalDatabaseSeeding.seededFlagKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: LocalDatabaseSeeding.seededFlagKey)
        super.tearDown()
    }

    func test_처음_seedIfNeeded를_호출하면_번들_시드_데이터가_삽입된다() async throws {
        let context = LocalDatabaseContext(modelContainer: LocalDatabaseSchema.makeInMemoryContainer())

        try await withDependencies {
            $0.localDatabaseContext = context
        } operation: {
            try await LocalDatabaseSeeding.liveValue.seedIfNeeded()
        }

        let word = try await context.fetch(FetchDescriptor<WordEntity>(
            predicate: #Predicate<WordEntity> { $0.id == 1 }
        )).first
        XCTAssertEqual(word?.word, "an")
    }

    func test_이미_시딩됐으면_다시_호출해도_아무것도_삽입하지_않는다() async throws {
        UserDefaults.standard.set(true, forKey: LocalDatabaseSeeding.seededFlagKey)
        let context = LocalDatabaseContext(modelContainer: LocalDatabaseSchema.makeInMemoryContainer())

        try await withDependencies {
            $0.localDatabaseContext = context
        } operation: {
            try await LocalDatabaseSeeding.liveValue.seedIfNeeded()
        }

        let count = try await context.fetch(FetchDescriptor<WordEntity>()).count
        XCTAssertEqual(count, 0, "시딩이 스킵됐어야 하는데 데이터가 존재한다")
    }
}
