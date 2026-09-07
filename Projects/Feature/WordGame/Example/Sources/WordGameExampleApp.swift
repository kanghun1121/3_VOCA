import SwiftUI

import FeatureWordGame
import DomainInterface

import Dependencies

@main
struct WordGameExampleApp: App {
    init() {
        prepareDependencies {
            $0.lessonRepository.fetchDetail = { id in .previewWith3Words(id: id) }
            $0.audioRepository.prefetch = { _ in }
            $0.learningHistoryRepository.complete = { _ in }
        }
    }

    var body: some Scene {
        WindowGroup {
            ExampleRootView()
        }
    }
}

private extension Lesson {
    static func previewWith3Words(id: String) -> Lesson {
        Lesson(
            id: id,
            level: 1,
            lessonNumber: 1,
            cefrLevel: "A1",
            words: [
                Lesson.Word(
                    id: "w1",
                    term: "apple",
                    pronunciation: "/ˈæp.əl/",
                    definitions: [.init(id: "d1", partOfSpeech: .noun, meaning: "사과")],
                    distractors: ["바나나", "포도", "딸기"],
                    audioUrl: ""
                ),
                Lesson.Word(
                    id: "w2",
                    term: "brave",
                    pronunciation: "/breɪv/",
                    definitions: [.init(id: "d2", partOfSpeech: .adjective, meaning: "용감한")],
                    distractors: ["겁쟁이", "느린", "조용한"],
                    audioUrl: ""
                ),
                Lesson.Word(
                    id: "w3",
                    term: "create",
                    pronunciation: "/kriˈeɪt/",
                    definitions: [.init(id: "d3", partOfSpeech: .verb, meaning: "만들다, 창조하다")],
                    distractors: ["파괴하다", "멈추다", "잊다"],
                    audioUrl: ""
                ),
            ]
        )
    }
}

struct ExampleRootView: View {
    @State private var destination: WordGameViewModel?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Button("Recognition 부터") {
                    destination = WordGameViewModel(lessonID: "demo", startingFrom: .recognition)
                }
                Button("MultipleChoice 부터") {
                    destination = WordGameViewModel(lessonID: "demo", startingFrom: .multipleChoice)
                }
                Button("Spelling 부터") {
                    destination = WordGameViewModel(lessonID: "demo", startingFrom: .spelling)
                }
            }
            .navigationDestination(item: $destination) { vm in
                WordGameView(viewModel: vm)
            }
        }
    }
}
