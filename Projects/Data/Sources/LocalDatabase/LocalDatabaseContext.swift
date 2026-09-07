import Foundation
import SwiftData

import Dependencies

enum LocalDatabaseError: Error, Equatable {
    case wordNotFound(Int)
    case lessonNotFound(Int)
    case invalidWordID(String)
    case invalidLessonID(String)
}

/// SwiftData `ModelContainer`/`ModelContext`를 소유하는 유일한 지점. 제네릭 fetch/insert/save만
/// 알고 도메인(Word/Lesson/Level)에 대해서는 전혀 모른다 — 도메인별 조회/정렬/매핑은 이 컨텍스트를
/// 공유해서 쓰는 `WordLocalDataSource`/`LessonLocalDataSource`/`LevelLocalDataSource`의 책임이다.
///
/// Data 모듈 내부 전용이라 `public`이 아니다 — App/Feature는 이 타입의 존재 자체를 모른다.
@ModelActor
actor LocalDatabaseContext {
    func fetch<T: PersistentModel>(_ descriptor: FetchDescriptor<T>) throws -> [T] {
        try modelContext.fetch(descriptor)
    }

    func insert(_ model: some PersistentModel) {
        modelContext.insert(model)
    }

    func save() throws {
        try modelContext.save()
    }

    /// 조회→분기→쓰기가 하나의 액터 격리 안에서 원자적으로 일어나야 하는 upsert류 작업을 위한
    /// 탈출구. `fetch`/`insert`/`save`만으로는 "기존 값이 있으면 갱신, 없으면 삽입"을 안전하게
    /// 표현할 수 없다(중간에 다른 호출이 끼어들 여지가 생김).
    func withContext<T>(_ body: (ModelContext) throws -> T) rethrows -> T {
        try body(modelContext)
    }
}

extension LocalDatabaseContext: DependencyKey {
    static let liveValue = LocalDatabaseContext(modelContainer: LocalDatabaseSchema.makeContainer())
}

extension DependencyValues {
    var localDatabaseContext: LocalDatabaseContext {
        get { self[LocalDatabaseContext.self] }
        set { self[LocalDatabaseContext.self] = newValue }
    }
}
