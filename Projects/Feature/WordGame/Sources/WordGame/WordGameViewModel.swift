import Foundation
import SwiftUI

import DomainInterface

import Dependencies

@Observable
@MainActor
public final class WordGameViewModel {
    enum ActiveStage {
        case loading
        case launch(onStart: () -> Void)
        case recognition(RecognitionViewModel)
        case multipleChoice(MultipleChoiceViewModel)
        case spelling(SpellingViewModel)
        case stageEnd(title: String, onContinue: () -> Void)
        case gameComplete(wordCount: Int, onDismiss: () -> Void)
        case error(String)
    }

    public enum StartingStage {
        case recognition
        case multipleChoice
        case spelling
    }

    private(set) var activeStage: ActiveStage = .loading
    var dismiss = false
    private(set) var finishGameTask: Task<Void, Never>?
    private let lessonID: String
    private let startingStage: StartingStage

    @ObservationIgnored @Dependency(\.lessonRepository) private var lessonRepository
    @ObservationIgnored @Dependency(\.audioRepository) private var audioRepository
    @ObservationIgnored @Dependency(\.learningHistoryRepository) private var learningHistoryRepository

    public init(
        lessonID: String,
        startingFrom: StartingStage = .recognition
    ) {
        self.lessonID = lessonID
        self.startingStage = startingFrom
    }

    func load() async {
        do {
            let lesson = try await lessonRepository.fetchDetail(lessonID)
            // "프리페치 세팅" — 이 레슨의 모든 단어를 한 번에 넘겨 로컬에 미리 받아두게 한다.
            // await로 완료까지 기다리므로, 이 줄이 끝난 뒤부터는 게임 화면(Recognition/
            // MultipleChoice)이 각 단어를 재생할 때(WordPronunciationPlayer.play) 전부
            // 캐시 hit이어야 정상 — 즉 여기가 "오디오 세팅"이 실제로 일어나는 지점이다.
            let audioItems = lesson.words.map { ($0.term, $0.audioUrl) }
            await audioRepository.prefetch(audioItems)
            let words = lesson.words
            switch startingStage {
            case .recognition:    showLaunch(words: words)
            case .multipleChoice: startMultipleChoice(words: words)
            case .spelling:       startSpelling(words: words)
            }
        } catch {
            activeStage = .error("단어를 불러오지 못했습니다.")
        }
    }

    private func showLaunch(words: [Lesson.Word]) {
        withAnimation(.easeInOut(duration: 0.3)) {
            activeStage = .launch(onStart: { [weak self] in self?.startRecognition(words: words) })
        }
    }

    private func startRecognition(words: [Lesson.Word]) {
        let vm = RecognitionViewModel(
            words: words,
            onCompleted: { [weak self] in self?.showStageEnd(title: "인식 단계 종료!", onContinue: { self?.startMultipleChoice(words: words) }) },
            onClose: { [weak self] in self?.dismiss = true }
        )
        withAnimation(.easeInOut(duration: 0.3)) {
            activeStage = .recognition(vm)
        }
    }

    private func startMultipleChoice(words: [Lesson.Word]) {
        let vm = MultipleChoiceViewModel(
            words: words,
            onCompleted: { [weak self] in self?.showStageEnd(title: "뜻 단계 종료!", onContinue: { self?.startSpelling(words: words) }) },
            onClose: { [weak self] in self?.dismiss = true }
        )
        withAnimation(.easeInOut(duration: 0.3)) {
            activeStage = .multipleChoice(vm)
        }
    }

    private func startSpelling(words: [Lesson.Word]) {
        let vm = SpellingViewModel(
            words: words,
            onCompleted: { [weak self] in self?.showGameComplete(wordCount: words.count) },
            onClose: { [weak self] in self?.dismiss = true }
        )
        withAnimation(.easeInOut(duration: 0.3)) {
            activeStage = .spelling(vm)
        }
    }

    private func showGameComplete(wordCount: Int) {
        withAnimation(.easeInOut(duration: 0.3)) {
            activeStage = .gameComplete(wordCount: wordCount, onDismiss: { [weak self] in self?.finishGame() })
        }
    }

    private func showStageEnd(title: String, onContinue: @escaping () -> Void) {
        withAnimation(.easeInOut(duration: 0.3)) {
            activeStage = .stageEnd(title: title, onContinue: onContinue)
        }
    }

    private func finishGame() {
        finishGameTask = Task { [weak self] in
            guard let self else { return }
            if let id = Int(lessonID) {
                try? await learningHistoryRepository.complete(id)
            }
            dismiss = true
        }
    }
}
