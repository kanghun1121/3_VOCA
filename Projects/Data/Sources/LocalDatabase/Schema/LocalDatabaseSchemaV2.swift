import SwiftData

/// #106 리팩토링 이후 스키마(5개 엔티티). `WordMeaningEntity`/`LessonWordEntity`가 각각
/// `WordEntity.meanings`/`LessonEntity.orderedWordIDs`로 흡수되어 사라졌다. `ChatHistoryEntity`가
/// 추가된 V3로 대체됐으므로, 이제 이 버전은 "현재"가 아니라 V1과 같은 과거 스냅샷 역할이다 —
/// 다만 이 5개 엔티티 자체는 V3에서도 모양이 안 바뀌었으므로 별도로 복제하지 않고 최신 클래스를
/// 그대로 참조한다(V1의 `LevelEntity`/`WordExampleEntity`/`LearningHistoryEntity`와 동일한 이유).
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
