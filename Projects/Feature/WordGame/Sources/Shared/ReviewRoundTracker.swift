import Foundation

import DomainInterface

/// 메인 라운드에서 오답 처리된 단어를 추적하고, 복습 라운드로 전환할 시점과 그 대상 단어 목록을
/// 판단한다. 화면 갱신(showWord 호출 등)은 호출부의 책임으로 남긴다.
struct ReviewRoundTracker {
    private(set) var isReviewRound = false
    private var reviewWords: [Lesson.Word] = []
    private var incorrectWordIDs: Set<String> = []

    /// 메인 라운드에서 틀린 단어를 등록한다. 이미 복습 라운드 중이거나 이미 등록된 단어면 무시한다.
    mutating func registerIncorrect(_ word: Lesson.Word) {
        guard !isReviewRound, !incorrectWordIDs.contains(word.id) else { return }
        incorrectWordIDs.insert(word.id)
        reviewWords.append(word)
    }

    /// 현재 라운드에서 진행해야 할 단어 목록(메인 라운드면 원본, 복습 라운드면 오답 목록).
    func currentWords(mainWords: [Lesson.Word]) -> [Lesson.Word] {
        isReviewRound ? reviewWords : mainWords
    }

    /// 라운드 종료 시 호출한다. 복습할 오답이 남아있으면 복습 라운드로 전환하고 true를 반환한다.
    mutating func startReviewRoundIfNeeded() -> Bool {
        guard !isReviewRound, !reviewWords.isEmpty else { return false }
        isReviewRound = true
        return true
    }
}
