import Foundation

import DomainInterface
import FeatureVocabulary
import FeatureWordGame

import Dependencies
import SwiftUINavigation

@Observable
@MainActor
public final class LessonDetailViewModel {
    enum LessonDetailUIState: Equatable {
        case loading
        case loaded(Lesson)
        case error(String)
    }

    @CasePathable
    public enum Destination {
        case vocabularyList(VocabularyListViewModel)
        case wordGame(WordGameViewModel)
    }

    var destination: Destination?

    private(set) var uiState: LessonDetailUIState = .loading
    private(set) var learningHistory: LearningHistory?
    @ObservationIgnored private(set) var historyObservationTask: Task<Void, Never>?
    private let lessonID: String

    @ObservationIgnored @Dependency(\.loadLessonDetailUseCase) private var loadLessonDetailUseCase
    @ObservationIgnored @Dependency(\.learningHistoryRepository) private var learningHistoryRepository

    public init(lessonID: String) {
        self.lessonID = lessonID
    }

    public func onAppear() async {
        guard historyObservationTask == nil else { return }

        historyObservationTask = Task {
            for await history in learningHistoryRepository.stream(lessonID) {
                self.learningHistory = history
            }
        }

        do {
            let (lesson, _) = try await loadLessonDetailUseCase.execute(lessonID)
            uiState = .loaded(lesson)
        } catch {
            uiState = .error("레슨 정보를 불러오지 못했습니다.")
        }
    }

    public func didTapVocabularyList() {
        destination = .vocabularyList(VocabularyListViewModel(lessonID: lessonID))
    }

    public func didTapGame() {
        destination = .wordGame(WordGameViewModel(lessonID: lessonID))
    }

    deinit {
        historyObservationTask?.cancel()
    }
}
