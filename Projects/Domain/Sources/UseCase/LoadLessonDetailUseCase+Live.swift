import Foundation

import DomainInterface

import Dependencies

extension LoadLessonDetailUseCase: DependencyKey {
    public static let liveValue = LoadLessonDetailUseCase(
        execute: { id in
            @Dependency(\.lessonRepository) var lessonRepository
            @Dependency(\.audioRepository) var audioRepository

            let lesson = try await lessonRepository.fetchDetail(id)
            let audioItems = lesson.words.map { ($0.term, $0.audioUrl) }
            let audioReady = Task { await audioRepository.prefetch(audioItems) }
            return (lesson, audioReady)
        }
    )
}
