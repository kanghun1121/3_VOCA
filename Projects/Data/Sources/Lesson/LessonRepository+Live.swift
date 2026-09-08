import Foundation

import DomainInterface

import Dependencies

extension LessonRepository: DependencyKey {
    public static let liveValue = LessonRepository(
        fetchDetail: { id in
            @Dependency(\.lessonLocalDataSource) var lessonLocalDataSource
            @Dependency(\.levelLocalDataSource) var levelLocalDataSource
            @Dependency(\.wordLocalDataSource) var wordLocalDataSource

            let lessonID = try numericID(from: id)
            guard let entity = try await lessonLocalDataSource.lesson(id: lessonID) else {
                throw LocalDatabaseError.lessonNotFound(lessonID)
            }
            // 정적 구조는 두 도메인에 흩어져 있다 — Lesson(정렬된 단어 id 포함)은
            // lessonLocalDataSource, 단어 상세는 wordLocalDataSource, cefr 등급은
            // levelLocalDataSource. 여기서만 셋을 조합한다(각 DataSource는 서로를 모른다).
            let level = try await levelLocalDataSource.level(id: entity.levelID)
            let wordIDs = entity.orderedWordIDs
            let wordsByID = try await wordLocalDataSource.lessonWords(ids: wordIDs)
            let words = wordIDs.compactMap { wordsByID[$0] }

            return entity.toLesson(cefrLabel: level?.cefrLabel ?? "", words: words)
        }
    )
}

private func numericID(from id: String) throws -> Int {
    guard let value = Int(id.components(separatedBy: "_").last ?? id) else {
        throw LocalDatabaseError.invalidLessonID(id)
    }
    return value
}
