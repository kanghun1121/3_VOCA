import Foundation

import DomainInterface

import Dependencies

/// Level/Lesson 콘텐츠와 완료 이력이 전부 로컬 시드/로컬 DB로 제공되므로 원격 진행 상태 병합은
/// 더 이상 하지 않는다. 원격 진행 상태 조회(`VocabularyLibraryRemoteDataSource`)와 그 병합
/// 로직(`VocabularyLibraryMerge`)은 완전히 제거했다 — 서버 진행 상태 동기화가 다시 필요해지면
/// 그때 새로 설계한다.
extension VocabularyLibraryRepository: DependencyKey {
    public static let liveValue: VocabularyLibraryRepository = {
        @Dependency(\.vocabularyLibraryStore) var store
        @Dependency(\.levelLocalDataSource) var levelDataSource
        @Dependency(\.lessonLocalDataSource) var lessonDataSource
        @Dependency(\.learningHistoryLocalDataSource) var historyDataSource

        // 정적 구조(레벨 이름/난이도/레슨 번호/레슨당 단어 수)를 로컬 시드에서 조립한 뒤,
        // 완료 이력(`LearningHistoryEntity`, 완료된 레슨만 한 행)을 lessonID(Int, 로컬 DB
        // 공통 id)로 덧입혀 진행 상태를 계산한다 — 행이 있으면 `.completed`, 없으면
        // `.notStarted`. `accuracy`/`wordsCompleted`(단어별 정답률)는 로컬에 저장하지 않기로
        // 확정했으므로(완료 여부만 로컬화) 완료된 레슨도 `accuracy: nil`, `wordsCompleted:
        // totalWords`로 채운다. stream(최초 스냅샷)과 refresh(수동 새로고침) 둘 다에서 쓰인다.
        @Sendable
        func refreshVocabularyLibrary() async throws {
            var summaries: [LevelSummary] = []
            for entity in try await levelDataSource.allLevels() {
                let lessons = try await lessonDataSource.lessons(levelID: entity.id)
                summaries.append(entity.toStaticSummary(lessons: lessons))
            }

            let completions = try await historyDataSource.allCompletions()
            let completionByLessonID = completions.reduce(into: [String: LearningHistoryEntity]()) { result, entity in
                result[String(entity.lessonID)] = entity
            }

            let levels = summaries.map { level -> LevelSummary in
                let lessons = level.lessons.map { lesson -> LessonProgress in
                    guard let completion = completionByLessonID[lesson.id] else { return lesson }
                    return LessonProgress(
                        id: lesson.id,
                        lessonNumber: lesson.lessonNumber,
                        totalWords: lesson.totalWords,
                        status: .completed,
                        lastStudiedAt: completion.lastStudiedAt,
                        accuracy: nil,
                        wordsCompleted: lesson.totalWords
                    )
                }
                return LevelSummary(
                    id: level.id,
                    level: level.level,
                    name: level.name,
                    difficulty: level.difficulty,
                    totalLessons: level.totalLessons,
                    completedLessons: lessons.filter { $0.status == .completed }.count,
                    lessons: lessons
                )
            }

            await store.set(VocabularyLibrary(levels: levels))
        }

        return VocabularyLibraryRepository(
            stream: {
                AsyncStream { continuation in
                    Task {
                        let id = UUID()
                        await store.register(id: id, continuation: continuation)
                        try? await refreshVocabularyLibrary()
                    }
                }
            },
            refresh: {
                try await refreshVocabularyLibrary()
            }
        )
    }()
}
