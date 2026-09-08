import Foundation
import SwiftData

enum LocalDatabaseSchema {
    static func makeContainer() -> ModelContainer {
        // 번들 시드가 유일한 데이터 원본이라 CloudKit 동기화 대상이 아니다.
        let configuration = ModelConfiguration(cloudKitDatabase: .none)
        let schema = Schema(versionedSchema: LocalDatabaseSchemaV2.self)

        if let container = try? ModelContainer(
            for: schema,
            migrationPlan: LocalDatabaseMigrationPlan.self,
            configurations: configuration
        ) {
            return container
        }

        // 콘텐츠는 번들 시드에서 재생성 가능하므로, 손상된 스토어를 지우고 새로 만드는 편이
        // 크래시보다 낫다 — 이 경로는 LearningHistoryEntity(학습 이력)도 함께 잃는다.
        try? FileManager.default.removeItem(at: configuration.url)
        if let recreated = try? ModelContainer(
            for: schema,
            migrationPlan: LocalDatabaseMigrationPlan.self,
            configurations: configuration
        ) {
            return recreated
        }

        // 그래도 실패하면(디스크 자체 문제 등) 이번 세션 한정으로 in-memory 컨테이너를 써서
        // 최소한 앱이 크래시하지 않고 동작하도록 한다.
        return try! ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    static func makeInMemoryContainer() -> ModelContainer {
        // 인자가 전부 상수라 실패 원인이 스키마 정의 자체의 오류뿐이다 — 테스트 전용 경로이므로
        // 조용히 폴백하기보다 즉시 실패해 원인을 바로 드러내는 편이 낫다. 마이그레이션 대상이
        // 될 기존 스토어가 없는 새 in-memory 컨테이너라 migrationPlan은 필요 없다.
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: Schema(versionedSchema: LocalDatabaseSchemaV2.self), configurations: configuration)
    }
}
