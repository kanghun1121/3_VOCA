import Foundation

import Dependencies

/// 앱 시작 시 로컬 DB 시딩을 트리거하는 유일한 진입점. `AppViewModel`이 직접 호출하므로
/// public이다. 최초 1회만 실제로 시딩하고, 이미 시딩됐으면 즉시 반환한다(<1ms).
public struct LocalDatabaseSeeding: Sendable {
    public var seedIfNeeded: @Sendable () async throws -> Void

    public init(seedIfNeeded: @escaping @Sendable () async throws -> Void) {
        self.seedIfNeeded = seedIfNeeded
    }
}

extension LocalDatabaseSeeding: DependencyKey {
    // 테스트에서 격리를 위해 리셋할 수 있도록 internal로 둔다(모듈 밖으로는 노출 안 됨).
    // #106에서 v1 → v2로 올렸다: 스키마 마이그레이션(LocalDatabaseMigrationPlan) 후
    // WordEntity.meanings/LessonEntity.orderedWordIDs가 비어 있으므로 재시딩이 필요하다.
    static let seededFlagKey = "localDatabase.seeded.v2"

    public static let liveValue = LocalDatabaseSeeding(seedIfNeeded: {
        guard !UserDefaults.standard.bool(forKey: Self.seededFlagKey) else { return }
        @Dependency(\.localDatabaseContext) var context
        @Dependency(\.wordLocalDataSource) var word
        @Dependency(\.lessonLocalDataSource) var lesson
        @Dependency(\.levelLocalDataSource) var level
        // 저장 성공 후에만 플래그를 기록한다 — 실패 시 다음 실행에서 처음부터 재시도된다.
        try await LocalDatabaseSeeder.seed(word: word, lesson: lesson, level: level, context: context)
        UserDefaults.standard.set(true, forKey: Self.seededFlagKey)
    })
}

extension LocalDatabaseSeeding: TestDependencyKey {
    public static let testValue = LocalDatabaseSeeding(
        seedIfNeeded: unimplemented("\(Self.self).seedIfNeeded", placeholder: ())
    )
}

public extension DependencyValues {
    var localDatabaseSeeding: LocalDatabaseSeeding {
        get { self[LocalDatabaseSeeding.self] }
        set { self[LocalDatabaseSeeding.self] = newValue }
    }
}
