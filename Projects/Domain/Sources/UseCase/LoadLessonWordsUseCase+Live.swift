import Foundation

import DomainInterface

import Dependencies

extension LoadLessonWordsUseCase: DependencyKey {
    public static let liveValue = LoadLessonWordsUseCase(
        execute: { id in
            @Dependency(\.lessonRepository) var lessonRepository
            @Dependency(\.wordRepository) var wordRepository

            let lesson = try await lessonRepository.fetchDetail(id)
            let wordIDs = lesson.words.map(\.id)
            Task { await wordRepository.prefetchDetails(wordIDs) }
            return lesson
        }
    )
}
