import SwiftData

/// #106 리팩토링 이후 스키마(5개 엔티티). `WordMeaningEntity`/`LessonWordEntity`가 각각
/// `WordEntity.meanings`/`LessonEntity.orderedWordIDs`로 흡수되어 사라졌다. 최신 소스 트리의
/// 엔티티 정의를 그대로 참조한다 — `LocalDatabaseSchemaV1`과 달리 이 버전은 스냅샷이 아니라
/// "현재"이므로 별도로 복제하지 않는다.
enum LocalDatabaseSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            LevelEntity.self,
            LessonEntity.self,
            WordEntity.self,
            WordExampleEntity.self,
            LearningHistoryEntity.self,
        ]
    }
}
