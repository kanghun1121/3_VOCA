import SwiftData

/// V2(5종) + `ChatHistoryEntity`(챗봇 로컬 캐시, 서브플랜 9) = 6종. 최신 소스 트리의 엔티티
/// 정의를 그대로 참조한다 — `LocalDatabaseSchemaV2`와 달리 이 버전은 스냅샷이 아니라
/// "현재"이므로 별도로 복제하지 않는다.
///
/// `ChatHistoryEntity`는 완전히 새로운 엔티티라 다른 엔티티는 전혀 안 바뀌었지만, 새 엔티티
/// 추가도 스키마 해시가 바뀌는 변경이라 버전을 올려야 한다 — V2를 직접 수정했다가 이미 V2
/// 스토어가 있는 실기기/시뮬레이터에서 마이그레이션 실패로 로컬 DB 전체(Lesson 포함)가 안
/// 뜨는 회귀가 실제로 발생했다(2026-09-11).
enum LocalDatabaseSchemaV3: VersionedSchema {
    static let versionIdentifier = Schema.Version(3, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            LevelEntity.self,
            LessonEntity.self,
            WordEntity.self,
            WordExampleEntity.self,
            LearningHistoryEntity.self,
            ChatHistoryEntity.self,
        ]
    }
}
