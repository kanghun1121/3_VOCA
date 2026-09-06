import Foundation

import DomainInterface

import Dependencies
import SwiftUINavigation

@Observable
@MainActor
public final class MultipleChoiceViewModel {
    enum ViewState: Equatable {
        case active
        case revealed(selected: String)
    }

    enum AlertAction {
        case confirmDiscard
    }

    @CasePathable
    enum Destination {
        case alert(AlertState<AlertAction>)
    }

    var destination: Destination?

    private(set) var viewState: ViewState = .active
    private(set) var currentWord: Lesson.Word?
    private(set) var choices: [String] = []
    private(set) var wordIndex: Int = 0
    private(set) var totalWords: Int = 0
    private(set) var advanceTask: Task<Void, Never>?
    private var audioTask: Task<Void, Never>?
    private var reviewTracker = ReviewRoundTracker()
    var isReviewRound: Bool { reviewTracker.isReviewRound }
    private let words: [Lesson.Word]
    private let onCompleted: () -> Void
    private let onClose: () -> Void
    private let clock: any Clock<Duration>

    @ObservationIgnored @Dependency(\.soundClient) private var soundClient
    @ObservationIgnored @Dependency(\.audioRepository) private var audioRepository
    @ObservationIgnored @Dependency(\.audioPlayerRepository) private var audioPlayerRepository

    private var pronunciationPlayer: WordPronunciationPlayer {
        WordPronunciationPlayer(
            audioRepository: audioRepository,
            audioPlayerRepository: audioPlayerRepository
        )
    }

    init(
        words: [Lesson.Word],
        onCompleted: @escaping () -> Void,
        onClose: @escaping () -> Void,
        clock: any Clock<Duration> = ContinuousClock()
    ) {
        self.words = words
        self.totalWords = words.count
        self.onCompleted = onCompleted
        self.onClose = onClose
        self.clock = clock
    }

    func load() {
        showWord(at: 0)
    }

    func closeButtonTapped() {
        destination = .alert(
            AlertState(
                title: TextState("종료하시겠습니까?"),
                message: TextState("게임을 종료하면 학습된 이력은 저장되지 않습니다."),
                buttons: [
                    .destructive(TextState("종료"), action: .send(.confirmDiscard)),
                    .cancel(TextState("취소"))
                ]
            )
        )
    }

    func alertButtonTapped(_ action: AlertAction?) {
        switch action {
        case .confirmDiscard:
            advanceTask?.cancel()
            audioTask?.cancel()
            audioPlayerRepository.stop()
            onClose()
        case .none:
            break
        }
    }

    func choiceTapped(_ choice: String) {
        guard case .active = viewState else { return }
        guard let word = currentWord else { return }

        let isCorrect = choice == word.primaryMeaning
        if isCorrect {
            soundClient.playCorrect()
        } else {
            soundClient.playWrong()
            reviewTracker.registerIncorrect(word)
        }

        viewState = .revealed(selected: choice)

        advanceTask = Task { [weak self] in
            guard let self else { return }
            try? await self.clock.sleep(for: .milliseconds(1000))
            guard !Task.isCancelled else { return }
            showWord(at: wordIndex + 1)
        }
    }

    private func showWord(at index: Int) {
        let currentWords = reviewTracker.currentWords(mainWords: words)
        guard index < currentWords.count else {
            finishRound()
            return
        }

        let word = currentWords[index]
        wordIndex = index
        currentWord = word
        choices = makeChoices(for: word)
        viewState = .active

        audioTask?.cancel()
        audioTask = Task { [weak self] in
            guard let self else { return }
            await pronunciationPlayer.play(term: word.term, audioUrl: word.audioUrl)
        }
    }

    private func makeChoices(for word: Lesson.Word) -> [String] {
        (word.distractors + [word.primaryMeaning]).shuffled()
    }

    /// 메인 라운드 종료 시 오답이 있으면 복습 라운드를 시작하고, 없으면 완료 처리한다.
    private func finishRound() {
        if reviewTracker.startReviewRoundIfNeeded() {
            totalWords = reviewTracker.currentWords(mainWords: words).count
            showWord(at: 0)
        } else {
            onCompleted()
        }
    }
}
