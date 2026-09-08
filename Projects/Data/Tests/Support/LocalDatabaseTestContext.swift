import SwiftData

import Dependencies

@testable import Data

/// in-memory `LocalDatabaseContext` 생성 + `withDependencies` 주입 + 픽스처 커밋을 한 곳에 모은다.
/// 각 테스트 파일이 반복 정의하던 `makeContext()` + `withDependencies { ... }` 보일러플레이트를 대체한다.
struct LocalDatabaseTestContext {
    let context: LocalDatabaseContext

    init() {
        context = LocalDatabaseContext(modelContainer: LocalDatabaseSchema.makeInMemoryContainer())
    }

    /// 픽스처를 삽입하고 즉시 커밋한다 — insert 후 save를 빼먹어 조회가 비는 실수를 막는다.
    func seed(_ models: any PersistentModel...) async throws {
        for model in models {
            await context.insert(model)
        }
        try await context.save()
    }

    /// `localDatabaseContext`를 주입한 채 operation을 실행한다.
    func run<T>(_ operation: () async throws -> T) async throws -> T {
        try await withDependencies {
            $0.localDatabaseContext = context
        } operation: {
            try await operation()
        }
    }

    /// 회귀 가드용 카운트 조회.
    func count<T: PersistentModel>(_ type: T.Type) async throws -> Int {
        try await context.fetch(FetchDescriptor<T>()).count
    }
}
