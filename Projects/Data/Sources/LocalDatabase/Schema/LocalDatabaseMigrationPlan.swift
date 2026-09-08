import SwiftData

/// V1(#106 이전 7종) → V2(현재 5종) 전환 규칙. 엔티티 삭제 2건(`WordMeaningEntity`,
/// `LessonWordEntity`)과 속성 추가/삭제(각 기본값 있음)만 있어 경량(lightweight) 마이그레이션
/// 대상이다 — `LearningHistoryEntity`는 두 버전에서 동일해 그대로 이월되므로 학습 이력이
/// 보존된다. 삭제된 두 엔티티가 남기던 데이터(뜻/레슨-단어 순서)는 마이그레이션이 채워주지
/// 않으므로, 마이그레이션 직후 `LocalDatabaseSeeding`이 재시딩해서 채운다(seededFlagKey v2).
enum LocalDatabaseMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [LocalDatabaseSchemaV1.self, LocalDatabaseSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [.lightweight(fromVersion: LocalDatabaseSchemaV1.self, toVersion: LocalDatabaseSchemaV2.self)]
    }
}
