import XCTest

@testable import FeatureWordGame
import DomainInterface

final class ReviewRoundTrackerTests: XCTestCase {
    func test_초기상태에서는_메인라운드이며_currentWords가_원본을_그대로_반환한다() {
        let tracker = ReviewRoundTracker()
        let words = [makeWord(id: "w1"), makeWord(id: "w2")]

        XCTAssertFalse(tracker.isReviewRound)
        XCTAssertEqual(tracker.currentWords(mainWords: words), words)
    }

    func test_registerIncorrect로_등록한_단어는_복습라운드_시작후_currentWords에_포함된다() {
        var tracker = ReviewRoundTracker()
        let word = makeWord(id: "w1")

        tracker.registerIncorrect(word)
        _ = tracker.startReviewRoundIfNeeded()

        XCTAssertEqual(tracker.currentWords(mainWords: []), [word])
    }

    func test_같은_단어를_두번_등록해도_복습목록엔_한번만_들어간다() {
        var tracker = ReviewRoundTracker()
        let word = makeWord(id: "w1")

        tracker.registerIncorrect(word)
        tracker.registerIncorrect(word)
        _ = tracker.startReviewRoundIfNeeded()

        XCTAssertEqual(tracker.currentWords(mainWords: []), [word])
    }

    func test_오답이_없으면_startReviewRoundIfNeeded가_false를_반환하고_메인라운드를_유지한다() {
        var tracker = ReviewRoundTracker()

        let started = tracker.startReviewRoundIfNeeded()

        XCTAssertFalse(started)
        XCTAssertFalse(tracker.isReviewRound)
    }

    func test_오답이_있으면_startReviewRoundIfNeeded가_true를_반환하고_복습라운드로_전환된다() {
        var tracker = ReviewRoundTracker()
        let word = makeWord(id: "w1")
        tracker.registerIncorrect(word)

        let started = tracker.startReviewRoundIfNeeded()

        XCTAssertTrue(started)
        XCTAssertTrue(tracker.isReviewRound)
        XCTAssertEqual(tracker.currentWords(mainWords: [makeWord(id: "w2")]), [word])
    }

    func test_이미_복습라운드_중이면_registerIncorrect를_호출해도_무시된다() {
        var tracker = ReviewRoundTracker()
        let firstWord = makeWord(id: "w1")
        tracker.registerIncorrect(firstWord)
        _ = tracker.startReviewRoundIfNeeded()

        tracker.registerIncorrect(makeWord(id: "w2"))

        XCTAssertEqual(tracker.currentWords(mainWords: []), [firstWord])
    }
}

private func makeWord(id: String) -> Lesson.Word {
    Lesson.Word(
        id: id,
        term: "term_\(id)",
        pronunciation: "",
        definitions: [],
        distractors: [],
        audioUrl: ""
    )
}
