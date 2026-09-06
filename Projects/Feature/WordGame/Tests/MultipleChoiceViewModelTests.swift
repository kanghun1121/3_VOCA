import XCTest

import DomainInterface

import Dependencies

@testable import FeatureWordGame

@MainActor
final class MultipleChoiceViewModelTests: XCTestCase {
    func test_정답_선택시_revealed로_전환된다() {
        let lessonWord = Lesson.Word(
            id: "w1",
            term: "cat",
            pronunciation: "",
            definitions: [
                Lesson.Word.Definition(
                    id: "d1",
                    partOfSpeech: .noun,
                    meaning: "고양이"
                )
            ],
            distractors: ["개", "새"],
            audioUrl: ""
        )
        let word = lessonWord
        let vm = withDependencies {
            $0.soundClient = .previewValue
            $0.audioRepository.url = { _ in nil }
            $0.audioRepository.fetchURL = { _, _ in nil }
            $0.audioPlayerRepository.play = { _ in }
            $0.audioPlayerRepository.stop = {}
        } operation: {
            MultipleChoiceViewModel(
                words: [word],
                onCompleted: {},
                onClose: {},
                clock: ImmediateClock()
            )
        }

        vm.load()
        vm.choiceTapped("고양이")

        guard case .revealed(let selected) = vm.viewState else {
            XCTFail("viewState가 .revealed여야 합니다. 실제: \(vm.viewState)")
            return
        }
        XCTAssertEqual(selected, "고양이")
    }

    func test_5개중_3개_오답_2개_정답이면_복습라운드에_오답3개가_순서대로_들어간다() async {
        let entries: [(term: String, meaning: String, distractors: [String])] = [
            ("cat", "고양이", ["개", "새"]),
            ("dog", "개", ["고양이", "새"]),
            ("sun", "태양", ["달", "별"]),
            ("cup", "컵", ["접시", "그릇"]),
            ("run", "달리다", ["걷다", "서다"])
        ]
        let words = entries.enumerated().map { index, entry -> Lesson.Word in
            let lessonWord = Lesson.Word(
                id: "w\(index)",
                term: entry.term,
                pronunciation: "",
                definitions: [
                    Lesson.Word.Definition(
                        id: "d\(index)",
                        partOfSpeech: .noun,
                        meaning: entry.meaning
                    )
                ],
                distractors: entry.distractors,
                audioUrl: ""
            )
            return lessonWord
        }
        let vm = withDependencies {
            $0.soundClient = .previewValue
            $0.audioRepository.url = { _ in nil }
            $0.audioRepository.fetchURL = { _, _ in nil }
            $0.audioPlayerRepository.play = { _ in }
            $0.audioPlayerRepository.stop = {}
        } operation: {
            MultipleChoiceViewModel(
                words: words,
                onCompleted: {},
                onClose: {},
                clock: ImmediateClock()
            )
        }

        vm.load()

        vm.choiceTapped("개") // cat 오답 (정답은 "고양이")
        _ = await vm.advanceTask?.value
        vm.choiceTapped("개") // dog 정답
        _ = await vm.advanceTask?.value
        vm.choiceTapped("달") // sun 오답
        _ = await vm.advanceTask?.value
        vm.choiceTapped("접시") // cup 오답
        _ = await vm.advanceTask?.value
        vm.choiceTapped("달리다") // run 정답
        _ = await vm.advanceTask?.value

        XCTAssertTrue(vm.isReviewRound)
        XCTAssertEqual(vm.totalWords, 3)
        XCTAssertEqual(vm.currentWord?.term, "cat")

        vm.choiceTapped("고양이")
        _ = await vm.advanceTask?.value
        XCTAssertEqual(vm.currentWord?.term, "sun")

        vm.choiceTapped("태양")
        _ = await vm.advanceTask?.value
        XCTAssertEqual(vm.currentWord?.term, "cup")
    }

    func test_메인라운드에서_전부_오답을_선택하면_전부_복습배열에_들어간다() async {
        let entries: [(term: String, meaning: String, distractors: [String])] = [
            ("cat", "고양이", ["개", "새"]),
            ("dog", "개", ["고양이", "새"]),
            ("sun", "태양", ["달", "별"])
        ]
        let words = entries.enumerated().map { index, entry -> Lesson.Word in
            let lessonWord = Lesson.Word(
                id: "w\(index)",
                term: entry.term,
                pronunciation: "",
                definitions: [
                    Lesson.Word.Definition(
                        id: "d\(index)",
                        partOfSpeech: .noun,
                        meaning: entry.meaning
                    )
                ],
                distractors: entry.distractors,
                audioUrl: ""
            )
            return lessonWord
        }
        let vm = withDependencies {
            $0.soundClient = .previewValue
            $0.audioRepository.url = { _ in nil }
            $0.audioRepository.fetchURL = { _, _ in nil }
            $0.audioPlayerRepository.play = { _ in }
            $0.audioPlayerRepository.stop = {}
        } operation: {
            MultipleChoiceViewModel(
                words: words,
                onCompleted: {},
                onClose: {},
                clock: ImmediateClock()
            )
        }

        vm.load()
        for entry in entries {
            vm.choiceTapped(entry.distractors[0])
            _ = await vm.advanceTask?.value
        }

        XCTAssertTrue(vm.isReviewRound)
        XCTAssertEqual(vm.totalWords, entries.count)
    }

    func test_choices가_distractors와_primaryMeaning으로_구성된다() {
        let lessonWord = Lesson.Word(
            id: "w1",
            term: "cat",
            pronunciation: "",
            definitions: [
                Lesson.Word.Definition(
                    id: "d1",
                    partOfSpeech: .noun,
                    meaning: "고양이"
                )
            ],
            distractors: ["개", "새"],
            audioUrl: ""
        )
        let word = lessonWord
        let vm = withDependencies {
            $0.soundClient = .previewValue
            $0.audioRepository.url = { _ in nil }
            $0.audioRepository.fetchURL = { _, _ in nil }
            $0.audioPlayerRepository.play = { _ in }
            $0.audioPlayerRepository.stop = {}
        } operation: {
            MultipleChoiceViewModel(
                words: [word],
                onCompleted: {},
                onClose: {}
            )
        }

        vm.load()

        XCTAssertEqual(Set(vm.choices), Set(["개", "새", "고양이"]))
    }

    func test_종료버튼을_누르면_destination이_alert상태가_된다() {
        let lessonWord = Lesson.Word(
            id: "w1",
            term: "cat",
            pronunciation: "",
            definitions: [
                Lesson.Word.Definition(
                    id: "d1",
                    partOfSpeech: .noun,
                    meaning: "고양이"
                )
            ],
            distractors: ["개", "새"],
            audioUrl: ""
        )
        let word = lessonWord
        let vm = withDependencies {
            $0.soundClient = .previewValue
            $0.audioRepository.url = { _ in nil }
            $0.audioRepository.fetchURL = { _, _ in nil }
            $0.audioPlayerRepository.play = { _ in }
            $0.audioPlayerRepository.stop = {}
        } operation: {
            MultipleChoiceViewModel(
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

    func test_alertButtonTapped_confirmDiscard시_onClose가_호출된다() {
        let lessonWord = Lesson.Word(
            id: "w1",
            term: "cat",
            pronunciation: "",
            definitions: [
                Lesson.Word.Definition(
                    id: "d1",
                    partOfSpeech: .noun,
                    meaning: "고양이"
                )
            ],
            distractors: ["개", "새"],
            audioUrl: ""
        )
        let word = lessonWord
        var isClosed = false
        let vm = withDependencies {
            $0.soundClient = .previewValue
            $0.audioRepository.url = { _ in nil }
            $0.audioRepository.fetchURL = { _, _ in nil }
            $0.audioPlayerRepository.play = { _ in }
            $0.audioPlayerRepository.stop = {}
        } operation: {
            MultipleChoiceViewModel(
                words: [word],
                onCompleted: {},
                onClose: { isClosed = true }
            )
        }

        vm.alertButtonTapped(.confirmDiscard)

        XCTAssertTrue(isClosed)
    }

    func test_게임이_종료되면_onCompleted가_호출된다() async {
        let lessonWord = Lesson.Word(
            id: "w1",
            term: "cat",
            pronunciation: "",
            definitions: [
                Lesson.Word.Definition(
                    id: "d1",
                    partOfSpeech: .noun,
                    meaning: "고양이"
                )
            ],
            distractors: ["개", "새"],
            audioUrl: ""
        )
        let word = lessonWord
        var isCompleted = false
        let vm = withDependencies {
            $0.soundClient = .previewValue
            $0.audioRepository.url = { _ in nil }
            $0.audioRepository.fetchURL = { _, _ in nil }
            $0.audioPlayerRepository.play = { _ in }
            $0.audioPlayerRepository.stop = {}
        } operation: {
            MultipleChoiceViewModel(
                words: [word],
                onCompleted: { isCompleted = true },
                onClose: {},
                clock: ImmediateClock()
            )
        }

        vm.load()
        vm.choiceTapped("고양이")
        _ = await vm.advanceTask?.value

        XCTAssertTrue(isCompleted)
    }
}
