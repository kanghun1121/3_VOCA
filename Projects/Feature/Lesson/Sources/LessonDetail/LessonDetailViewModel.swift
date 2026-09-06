import Foundation

import DomainInterface
import FeatureVocabulary
import FeatureWordGame

import Dependencies
import SwiftUINavigation

@Observable
@MainActor
public final class SessionDetailViewModel {
    enum ViewState {
        case loading
        case loaded(Session)
        case error(String)
    }

    @CasePathable
    public enum Destination {
        case vocabularyList(VocabularyListViewModel)
        case wordGame(WordGameViewModel)
    }

    private(set) var viewState: ViewState = .loading
    var destination: Destination?

    @ObservationIgnored @Dependency(\.getSessionDetailUseCase) private var getSessionDetailUseCase
    @ObservationIgnored @Dependency(\.prefetchAudioUseCase) private var prefetchAudioUseCase
    private let sessionID: String
    private var audioPrefetchTask: Task<Void, Never>?

    public init(sessionID: String) {
        self.sessionID = sessionID
    }

    public func load() async {
        viewState = .loading
        
        do {
            let session = try await getSessionDetailUseCase.execute(sessionID)
            viewState = .loaded(session)
            // 게임/단어장 진입 전 대기 시간을 줄이기 위해, 세션 상세 화면에 머무는 동안 미리 오디오를 캐싱해둔다.
            let audioItems = session.words.map { ($0.term, $0.audioUrl) }
            audioPrefetchTask = Task { await prefetchAudioUseCase.execute(audioItems) }
        } catch {
            viewState = .error("세션 정보를 불러오지 못했습니다.")
        }
    }

    public func didTapVocabularyList() {
        destination = .vocabularyList(VocabularyListViewModel(sessionID: sessionID))
    }

    public func didTapGame() {
        guard let audioPrefetchTask else { return }
        destination = .wordGame(WordGameViewModel(sessionID: sessionID, audioPrefetchTask: audioPrefetchTask))
    }
}
