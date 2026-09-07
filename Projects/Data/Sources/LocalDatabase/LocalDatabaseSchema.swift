import SwiftData

enum LocalDatabaseSchema {
    static let models: [any PersistentModel.Type] = [
        LevelEntity.self,
        LessonEntity.self,
        LessonWordEntity.self,
        WordEntity.self,
        WordMeaningEntity.self,
        WordExampleEntity.self,
        LearningHistoryEntity.self,
    ]

    static func makeContainer() -> ModelContainer {
        // 번들 시드가 유일한 데이터 원본이라 CloudKit 동기화 대상이 아니다.
        let configuration = ModelConfiguration(cloudKitDatabase: .none)
        return try! ModelContainer(for: Schema(models), configurations: configuration)
    }

    static func makeInMemoryContainer() -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: Schema(models), configurations: configuration)
    }
}
