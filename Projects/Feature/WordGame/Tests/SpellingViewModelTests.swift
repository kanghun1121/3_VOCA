import XCTest

import DomainInterface

import Dependencies

@testable import FeatureWordGame

@MainActor
final class SpellingViewModelTests: XCTestCase {
    func test_복습라운드에서_첫글자가_힌트로_채워진다() async {
        let lessonWord = Lesson.Word(
            id: "w1",
            term: "cat",
            pronunciation: "",
            definitions: [],
            distractors: [],
            audioUrl: ""
        )
        let word = lessonWord
        let vm = withDependencies {
            $0.soundClient = .previewValue
        } operation: {
            SpellingViewModel(
                words: [word],
                onCompleted: {},
                onClose: {},
                clock: ImmediateClock()
            )
        }

        vm.load()
        vm.skipButtonTapped()
        _ = await vm.advanceTask?.value

        XCTAssertTrue(vm.isReviewRound)
        XCTAssertEqual(vm.inputText, "c")
        XCTAssertEqual(vm.slots.first, .hint("c"))
    }

    func test_5개중_3개_오답_2개_정답이면_복습라운드에_오답3개가_순서대로_들어간다() async {
        let terms = ["cat", "dog", "sun", "cup", "run"]
        let words = terms.enumerated().map { index, term -> Lesson.Word in
            let lessonWord = Lesson.Word(
                id: "w\(index)",
                term: term,
                pronunciation: "",
                definitions: [],
                distractors: [],
                audioUrl: ""
            )
            return lessonWord
        }
        let vm = withDependencies {
            $0.soundClient = .previewValue
        } operation: {
            SpellingViewModel(
                words: words,
                onCompleted: {},
                onClose: {},
                clock: ImmediateClock()
            )
        }

        vm.load()

        vm.inputText = "zzz" // cat 오답
        _ = await vm.advanceTask?.value
        vm.inputText = "dog" // dog 정답
        _ = await vm.advanceTask?.value
        vm.inputText = "zzz" // sun 오답
        _ = await vm.advanceTask?.value
        vm.inputText = "zzz" // cup 오답
        _ = await vm.advanceTask?.value
        vm.inputText = "run" // run 정답
        _ = await vm.advanceTask?.value

        XCTAssertTrue(vm.isReviewRound)
        XCTAssertEqual(vm.totalWords, 3)
        XCTAssertEqual(vm.currentWord?.term, "cat")

        vm.inputText = "cat"
        _ = await vm.advanceTask?.value
        XCTAssertEqual(vm.currentWord?.term, "sun")

        vm.inputText = "sun"
        _ = await vm.advanceTask?.value
        XCTAssertEqual(vm.currentWord?.term, "cup")
    }

    func test_메인라운드에서_스킵버튼을_모두_누르면_전부_복습배열에_들어간다() async {
        let terms = ["cat", "dog", "sun"]
        let words = terms.enumerated().map { index, term -> Lesson.Word in
            let lessonWord = Lesson.Word(
                id: "w\(index)",
                term: term,
                pronunciation: "",
                definitions: [],
                distractors: [],
                audioUrl: ""
            )
            return lessonWord
        }
        let vm = withDependencies {
            $0.soundClient = .previewValue
        } operation: {
            SpellingViewModel(
                words: words,
                onCompleted: {},
                onClose: {},
                clock: ImmediateClock()
            )
        }

        vm.load()
        for _ in terms {
            vm.skipButtonTapped()
            _ = await vm.advanceTask?.value
        }

        XCTAssertTrue(vm.isReviewRound)
        XCTAssertEqual(vm.totalWords, terms.count)
    }

    func test_대문자를_입력해도_소문자로_비교되어_정답처리된다() {
        let lessonWord = Lesson.Word(
            id: "w1",
            term: "cat",
            pronunciation: "",
            definitions: [],
            distractors: [],
            audioUrl: ""
        )
        let word = lessonWord
        let vm = withDependencies {
            $0.soundClient = .previewValue
        } operation: {
            SpellingViewModel(
                words: [word],
                onCompleted: {},
                onClose: {}
            )
        }

        vm.load()
        vm.inputText = "CAT"

        XCTAssertEqual(vm.viewState, .correct)
    }

    func test_종료버튼을_누르면_destination이_alert상태가_된다() {
        let lessonWord = Lesson.Word(
            id: "w1",
            term: "cat",
            pronunciation: "",
            definitions: [],
            distractors: [],
            audioUrl: ""
        )
        let word = lessonWord
        let vm = withDependencies {
            $0.soundClient = .previewValue
        } operation: {
            SpellingViewModel(
                words: [word],
                onCompleted: {},
                onClose: {}
            )
        }

        vm.closeButtonTapped()

        guard case .alert = vm.destination else {
            XCTFail("destination이 .alert여야 합니다. 실제: \(String(describing: vm.destination))")
            return
        }
    }

    func test_리뷰라운드일때_SlotState가_hint_cursor_empty이다() async {
        let lessonWord = Lesson.Word(
            id: "w1",
            term: "cat",
            pronunciation: "",
            definitions: [],
            distractors: [],
            audioUrl: ""
        )
        let word = lessonWord
        let vm = withDependencies {
            $0.soundClient = .previewValue
        } operation: {
            SpellingViewModel(
                words: [word],
                onCompleted: {},
                onClose: {},
                clock: ImmediateClock()
            )
        }

        vm.load()
        vm.skipButtonTapped()
        _ = await vm.advanceTask?.value

        XCTAssertEqual(vm.slots, [.hint("c"), .cursor, .empty])
    }

    func test_일반라운드일때_SlotState가_cursor_empty_empty이다() {
        let lessonWord = Lesson.Word(
            id: "w1",
            term: "cat",
            pronunciation: "",
            definitions: [],
            distractors: [],
            audioUrl: ""
        )
        let word = lessonWord
        let vm = withDependencies {
            $0.soundClient = .previewValue
        } operation: {
            SpellingViewModel(
                words: [word],
                onCompleted: {},
                onClose: {}
            )
        }

        vm.load()

        XCTAssertEqual(vm.slots, [.cursor, .empty, .empty])
    }

    func test_5글자중_4글자입력시_복습라운드에서_hint_filled_filled_filled_cursor이다() async {
        let lessonWord = Lesson.Word(
            id: "w1",
            term: "apple",
            pronunciation: "",
            definitions: [],
            distractors: [],
            audioUrl: ""
        )
        let word = lessonWord
        let vm = withDependencies {
            $0.soundClient = .previewValue
        } operation: {
            SpellingViewModel(
                words: [word],
                onCompleted: {},
                onClose: {},
                clock: ImmediateClock()
            )
        }

        vm.load()
        vm.skipButtonTapped()
        _ = await vm.advanceTask?.value

        vm.inputText = "appl"

        XCTAssertEqual(
            vm.slots,
            [.hint("a"), .filled("p"), .filled("p"), .filled("l"), .cursor]
        )
    }

    func test_게임이_종료되면_onCompleted가_호출된다() async {
        let lessonWord = Lesson.Word(
            id: "w1",
            term: "cat",
            pronunciation: "",
            definitions: [],
            distractors: [],
            audioUrl: ""
        )
        let word = lessonWord
        var isCompleted = false
        let vm = withDependencies {
            $0.soundClient = .previewValue
        } operation: {
            SpellingViewModel(
                words: [word],
                onCompleted: { isCompleted = true },
                onClose: {},
                clock: ImmediateClock()
            )
        }

        vm.load()
        vm.inputText = "cat"
        _ = await vm.advanceTask?.value

        XCTAssertTrue(isCompleted)
    }
}
