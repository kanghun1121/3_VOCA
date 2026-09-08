import SwiftData
import XCTest

@testable import Data

/// V1(#106 이전 7종) → V2(현재 5종) 경량 마이그레이션이 실제로 동작하는지, 특히 유일한
/// 사용자 상태인 `LearningHistoryEntity`가 보존되는지를 온디스크 스토어 라운드트립으로
/// 검증한다. in-memory 컨테이너로는 "기존 v1 스토어"가 없어 마이그레이션 자체를 재현할
/// 수 없으므로, 임시 파일 경로에 실제 V1 스토어를 만든 뒤 같은 경로를 V2+MigrationPlan으로
/// 다시 여는 방식을 쓴다.
final class LocalDatabaseMigrationTests: XCTestCase {
    private func makeTemporaryStoreURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("migration-test-\(UUID().uuidString).store")
    }

    private func cleanUp(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    func test_v1_스토어를_v2로_마이그레이션하면_학습이력이_보존되고_5개_엔티티가_정상_등록된다() throws {
        let url = makeTemporaryStoreURL()
        defer { cleanUp(url) }

        // 1) V1 스키마로 스토어를 만들고 학습 이력 1건을 저장한다.
        let firstCompletedAt = Date(timeIntervalSince1970: 0)
        let lastStudiedAt = Date(timeIntervalSince1970: 1000)
        do {
            let v1Container = try ModelContainer(
                for: Schema(versionedSchema: LocalDatabaseSchemaV1.self),
                configurations: ModelConfiguration(url: url)
            )
            let context = ModelContext(v1Container)
            context.insert(LearningHistoryEntity(
                lessonID: 1,
                firstCompletedAt: firstCompletedAt,
                lastStudiedAt: lastStudiedAt,
                studyCount: 2
            ))
            try context.save()
        }

        // 2) 같은 경로를 V2 스키마 + 마이그레이션 플랜으로 다시 연다.
        let v2Container = try ModelContainer(
            for: Schema(versionedSchema: LocalDatabaseSchemaV2.self),
            migrationPlan: LocalDatabaseMigrationPlan.self,
            configurations: ModelConfiguration(url: url)
        )
        let context = ModelContext(v2Container)

        // 학습 이력은 V1/V2에서 형태가 동일해 경량 마이그레이션이 그대로 이월해야 한다.
        let histories = try context.fetch(FetchDescriptor<LearningHistoryEntity>())
        XCTAssertEqual(histories.count, 1)
        XCTAssertEqual(histories.first?.lessonID, 1)
        XCTAssertEqual(histories.first?.studyCount, 2)
        XCTAssertEqual(histories.first?.firstCompletedAt, firstCompletedAt)
        XCTAssertEqual(histories.first?.lastStudiedAt, lastStudiedAt)

        // 콘텐츠 엔티티(뜻/레슨-단어를 흡수한 WordEntity/LessonEntity 포함)는 v1에 데이터가
        // 없었으므로 마이그레이션 후에도 비어 있어야 한다 — 크래시 없이 정상 등록만 확인한다.
        XCTAssertEqual(try context.fetch(FetchDescriptor<WordEntity>()).count, 0)
        XCTAssertEqual(try context.fetch(FetchDescriptor<LessonEntity>()).count, 0)
        XCTAssertEqual(try context.fetch(FetchDescriptor<LevelEntity>()).count, 0)
        XCTAssertEqual(try context.fetch(FetchDescriptor<WordExampleEntity>()).count, 0)
    }
}
