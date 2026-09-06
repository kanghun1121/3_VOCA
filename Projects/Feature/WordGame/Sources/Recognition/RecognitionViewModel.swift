import Foundation

import DomainInterface

import Dependencies
import SwiftUINavigation

@Observable
@MainActor
public final class RecognitionViewModel {
    enum ViewState: Equatable {
        case loading
        case active
        case revealing
    }

    enum AlertAction {
        case confirmDiscard
    }

    @CasePathable
    enum Destination {
        case alert(AlertState<AlertAction>)
    }

    var destination: Destination?

    private(set) var viewState: ViewState = .loading
    private(set) var currentWord: Lesson.Word?
    private(set) var countdown: Int = 3
    private(set) var ringProgress: Double = 1.0
    private(set) var wordIndex: Int = 0
    private(set) var totalWords: Int = 0
    private let words: [Lesson.Word]
    private let onCompleted: () -> Void
    private let onClose: () -> Void
    private var countdownTask: Task<Void, Never>?
    private var revealTask: Task<Void, Never>?
    private var audioTask: Task<Void, Never>?
    private let totalCountdown: Double = 3.0
    private var remainingSeconds: Double = 3.0

    @ObservationIgnored @Dependency(\.audioRepository) private var audioRepository
    @ObservationIgnored @Dependency(\.audioPlayerRepository) private var audioPlayerRepository

    private var pronunciationPlayer: WordPronunciationPlayer {
        WordPronunciationPlayer(
            audioRepository: audioRepository,
            audioPlayerRepository: audioPlayerRepository
        )
    }

    init(words: [Lesson.Word], onCompleted: @escaping () -> Void, onClose: @escaping () -> Void) {
        self.words = words
        self.totalWords = words.count
        self.onCompleted = onCompleted
        self.onClose = onClose
    }

    func start() {
        guard !words.isEmpty else {
            onCompleted()
            return
        }
        showWord(at: 0)
    }

    // X 버튼 — 남은 시간을 저장하고 타이머 Task를 즉시 cancel한 뒤 알럿 표시
    func closeButtonTapped() {
        remainingSeconds = ringProgress * totalCountdown
        countdownTask?.cancel()
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
            revealTask?.cancel()
            audioTask?.cancel()
            audioPlayerRepository.stop()
            onClose()
        case .none:
            startCountdown(remaining: remainingSeconds)
        }
    }

    func rememberedButtonTapped() {
        guard case .active = viewState else { return }
        countdownTask?.cancel()
        revealAndAdvance()
    }

    func forgotButtonTapped() {
        guard case .active = viewState else { return }
        countdownTask?.cancel()
        revealAndAdvance()
    }

    private func showWord(at index: Int) {
        guard index < words.count else {
            onCompleted()
            return
        }

        let word = setCurrentWord(at: index)

        audioTask?.cancel()
        audioTask = Task { [weak self] in
            guard let self else { return }
            await pronunciationPlayer.play(term: word.term, audioUrl: word.audioUrl)
        }

        startCountdown()
    }

    private func setCurrentWord(at index: Int) -> Lesson.Word {
        let word = words[index]
        wordIndex = index
        currentWord = word
        return word
    }

    private func startCountdown(remaining: Double = 3.0) {
        countdownTask?.cancel()
        ringProgress = remaining / totalCountdown
        countdown = Int(ceil(remaining))
        viewState = .active

        countdownTask = Task { [weak self] in
            guard let self else { return }
            let startDate = Date.now

            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(10))

                let left = remaining - Date.now.timeIntervalSince(startDate)
                updateProgress(timeLeft: max(0, left))
                if left <= 0 { break }
            }

            guard !Task.isCancelled else { return }
            revealAndAdvance()
        }
    }

    private func updateProgress(timeLeft: Double) {
        ringProgress = timeLeft / totalCountdown
        countdown = Int(ceil(timeLeft))
    }

    private func revealAndAdvance() {
        countdownTask?.cancel()
        viewState = .revealing
        revealTask?.cancel()
        revealTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            guard let self else { return }
            showWord(at: wordIndex + 1)
        }
    }
}
