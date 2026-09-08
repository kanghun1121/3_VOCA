import Foundation

import DomainInterface

import Dependencies
import SwiftUINavigation

@Observable
@MainActor
public final class WordListViewModel {
    enum ViewState {
        case loading
        case loaded(Lesson)
        case error(String)
    }

    @CasePathable
    enum Destination {
        case wordDetail(WordDetailViewModel)
    }

    var destination: Destination?

    private(set) var viewState: ViewState = .loading
    private(set) var learningHistory: LearningHistory?
    @ObservationIgnored private(set) var historyObservationTask: Task<Void, Never>?
    private let lessonID: String

    @ObservationIgnored @Dependency(\.loadLessonWordsUseCase) private var loadLessonWordsUseCase
    @ObservationIgnored @Dependency(\.learningHistoryRepository) private var learningHistoryRepository

    public init(lessonID: String) {
        self.lessonID = lessonID
    }

    public func load() async {
        if historyObservationTask == nil {
            historyObservationTask = Task {
                for await history in learningHistoryRepository.stream(lessonID) {
                    self.learningHistory = history
                }
            }
        }

        viewState = .loading
        do {
            let lesson = try await loadLessonWordsUseCase.execute(lessonID)
            viewState = .loaded(lesson)
        } catch {
            viewState = .error("단어 목록을 불러오지 못했습니다.")
        }
    }

    public func didTapWord(id: String) {
        guard case .loaded(let lesson) = viewState else { return }
        let wordIDs = lesson.words.map(\.id)
        guard let index = wordIDs.firstIndex(of: id) else { return }
        destination = .wordDetail(WordDetailViewModel(wordIDs: wordIDs, initialIndex: index))
    }

    deinit {
        historyObservationTask?.cancel()
    }
}
