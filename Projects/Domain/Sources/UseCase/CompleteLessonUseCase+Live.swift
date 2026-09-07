import Foundation

import DomainInterface

import Dependencies

extension CompleteLessonUseCase: DependencyKey {
    public static let liveValue = CompleteLessonUseCase(
        execute: { lessonID in
            @Dependency(\.learningHistoryRepository) var learningHistoryRepository
            @Dependency(\.vocabularyLibraryRepository) var vocabularyLibraryRepository

            try await learningHistoryRepository.complete(lessonID)
            try? await vocabularyLibraryRepository.refresh()
        }
    )
}
