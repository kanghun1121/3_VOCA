import Foundation

import DomainInterface

import Dependencies

extension LoadVocabularyListUseCase: DependencyKey {
    public static let liveValue = LoadVocabularyListUseCase(
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
