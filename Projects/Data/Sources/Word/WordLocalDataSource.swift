import Foundation
import SwiftData

import DomainInterface

import Dependencies

/// `WordEntity`(뜻 포함)+`WordExampleEntity`(전부 단어에 종속된 데이터)를 전담한다.
/// 단어 조회 API는 삭제되었으므로 Remote 대응 타입은 없다.
struct WordLocalDataSource: Sendable {
    @Dependency(\.localDatabaseContext) private var context

    func wordDetail(id: Int) async throws -> WordDetail {
        guard let entity = try await word(id: id) else {
            throw LocalDatabaseError.wordNotFound(id)
        }
        return entity.toWordDetail(examples: try await examples(wordID: id))
    }

    /// Lesson 조립용 배치 조회 — 반환되는 딕셔너리엔 순서 정보가 없으므로, 호출부(Lesson
    /// LocalDataSource가 아는 lesson_words의 position)가 원하는 순서로 재조립해야 한다.
    func lessonWords(ids: [Int]) async throws -> [Int: Lesson.Word] {
        guard !ids.isEmpty else { return [:] }

        let words = try await context.fetch(FetchDescriptor<WordEntity>(
            predicate: #Predicate { ids.contains($0.id) }
        ))

        return Dictionary(uniqueKeysWithValues: words.map { entity in
            (entity.id, entity.toLessonWord())
        })
    }

    func insertWords(_ words: [WordEntity]) async {
        for word in words { await context.insert(word) }
    }

    func insertExamples(_ examples: [WordExampleEntity]) async {
        for example in examples { await context.insert(example) }
    }

    // MARK: - Private

    private func word(id: Int) async throws -> WordEntity? {
        try await context.fetch(FetchDescriptor<WordEntity>(
            predicate: #Predicate { $0.id == id }
        )).first
    }

    private func examples(wordID: Int) async throws -> [WordExampleEntity] {
        try await context.fetch(FetchDescriptor<WordExampleEntity>(
            predicate: #Predicate { $0.wordID == wordID },
            sortBy: [SortDescriptor(\.order)]
        ))
    }
}

extension WordLocalDataSource: DependencyKey {
    static let liveValue = WordLocalDataSource()
}

// 상태가 없는 얇은 구조체라 test/live 구분이 의미 없다 — 실제 동작 차이는 내부에서
// resolve하는 `localDatabaseContext`(테스트가 개별적으로 오버라이드)에서 나온다.
extension WordLocalDataSource: TestDependencyKey {
    static let testValue = WordLocalDataSource()
}

extension DependencyValues {
    var wordLocalDataSource: WordLocalDataSource {
        get { self[WordLocalDataSource.self] }
        set { self[WordLocalDataSource.self] = newValue }
    }
}
