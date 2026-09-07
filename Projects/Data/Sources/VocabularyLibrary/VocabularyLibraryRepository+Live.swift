import Foundation

import DomainInterface

import Dependencies

/// 정적 구조(레벨 이름/난이도/레슨 번호/레슨당 단어 수)는 로컬 시드에서 조립한다 — 이 조립을
/// 전담하는 별도 타입은 만들지 않는다. Level+Lesson을 조합하는 소비자가 이 함수 하나뿐이라
/// 새 타입을 추가하면 "DataSource를 조합하는 DataSource"라는 불필요한 중복이 생긴다.
// internal(비공개 아님) — 로컬 스켈레톤 조립 로직을 독립적으로 테스트하기 위해 노출한다.
func localSkeleton() async throws -> [LevelSummary] {
    @Dependency(\.levelLocalDataSource) var level
    @Dependency(\.lessonLocalDataSource) var lesson

    var summaries: [LevelSummary] = []
    for entity in try await level.allLevels() {
        let lessons = try await lesson.lessons(levelID: entity.id)
        summaries.append(entity.toStaticSummary(lessons: lessons))
    }
    return summaries
}

private func refreshVocabularyLibrary(store: VocabularyLibraryStore) async throws {
    let local = try await localSkeleton()
    await store.set(VocabularyLibrary(levels: local))
}

/// Level/Lesson 콘텐츠가 전부 로컬 시드로 제공되므로 원격 진행 상태 병합은 더 이상 하지
/// 않는다. `VocabularyLibraryRemoteDataSource`/`VocabularyLibraryMerge`는 지금은 어디서도
/// 호출하지 않는 죽은 코드로 남겨둔다 — 서버 진행 상태 동기화가 다시 필요해지면 그때 다시 연결한다.
extension VocabularyLibraryRepository: DependencyKey {
    public static let liveValue: VocabularyLibraryRepository = {
        let store = VocabularyLibraryStore()
        return VocabularyLibraryRepository(
            stream: {
                AsyncStream { continuation in
                    let id = UUID()
                    continuation.onTermination = { _ in
                        Task { await store.unregister(id: id) }
                    }
                    Task {
                        await store.register(id: id, continuation: continuation)
                        try? await refreshVocabularyLibrary(store: store)
                    }
                }
            },
            refresh: {
                try await refreshVocabularyLibrary(store: store)
            }
        )
    }()
}
