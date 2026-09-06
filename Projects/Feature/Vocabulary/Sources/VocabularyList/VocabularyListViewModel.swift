import Foundation

import DomainInterface

import Dependencies
import SwiftUINavigation

@Observable
@MainActor
public final class VocabularyListViewModel {
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
    private let lessonID: String

    @ObservationIgnored @Dependency(\.loadVocabularyListUseCase) private var loadVocabularyListUseCase

    public init(lessonID: String) {
        self.lessonID = lessonID
    }

    public func load() async {
        viewState = .loading
        do {
            let lesson = try await loadVocabularyListUseCase.execute(lessonID)
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
}
