import SwiftUI

import FeatureLesson

import Dependencies

@main
struct LessonExampleApp: App {
    init() {
        prepareDependencies {
            $0.loadLessonDetailUseCase.execute = { id in (lesson: .preview(id: id), audioReady: Task {}) }
            $0.learningHistoryRepository.stream = { _ in
                AsyncStream { continuation in
                    continuation.yield(.preview)
                    continuation.finish()
                }
            }
            $0.learningLibraryRepository = .previewValue
        }
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                LessonDetailView(viewModel: LessonDetailViewModel(lessonID: "demo"))
            }
        }
    }
}
