import SwiftUI

import FeatureVocabulary

import Dependencies

@main
struct VocabularyExampleApp: App {
    init() {
        prepareDependencies {
            $0.loadVocabularyListUseCase = .previewValue
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
            VocabularyListView(viewModel: VocabularyListViewModel(lessonID: "demo"))
        }
    }
}
