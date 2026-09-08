import SwiftUI

import FeatureWord

import Dependencies

@main
struct WordExampleApp: App {
    init() {
        prepareDependencies {
            $0.loadLessonWordsUseCase = .previewValue
            $0.wordRepository.fetchDetail = { _ in .previewFixture }
            $0.audioRepository.url = { _ in nil }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

private struct ContentView: View {
    var body: some View {
        NavigationStack {
            WordListView(viewModel: WordListViewModel(lessonID: "demo"))
        }
    }
}
