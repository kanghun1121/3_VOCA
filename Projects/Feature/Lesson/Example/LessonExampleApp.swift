import SwiftUI

import FeatureLesson

import Dependencies

@main
struct VocaExampleApp: App {
    init() {
        prepareDependencies {
            $0.loadLessonDetailUseCase.execute = { id in (lesson: .preview(id: id), audioReady: Task {}) }
            $0.learningHistoryRepository.stream = { _ in
                AsyncStream { continuation in
                    continuation.yield(.preview)
                    continuation.finish()
                }
            }
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
