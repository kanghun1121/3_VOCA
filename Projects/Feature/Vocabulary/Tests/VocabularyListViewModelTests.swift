import XCTest

import DomainInterface
@testable import FeatureVocabulary

import Dependencies

@MainActor
final class VocabularyListViewModelTests: XCTestCase {
    func test_load_실패시_viewState가_error로_전환된다() async {
        let vm = withDependencies {
            $0.loadVocabularyListUseCase.execute = { _ in throw MockError.stub }
            $0.learningHistoryRepository.stream = { _ in makeHistoryStream([]) }
        } operation: {
            VocabularyListViewModel(lessonID: "t")
        }

        await vm.load()
        await vm.historyObservationTask?.value

        guard case .error = vm.viewState else {
            XCTFail("viewState가 .error여야 합니다. 실제: \(vm.viewState)")
            return
        }
    }

    func test_load_성공시_viewState가_loaded이며_Mock데이터가_올바르다() async {
        let vm = withDependencies {
            $0.loadVocabularyListUseCase = .previewValue
            $0.learningHistoryRepository.stream = { _ in makeHistoryStream([]) }
        } operation: {
            VocabularyListViewModel(lessonID: "t")
        }

        await vm.load()
        await vm.historyObservationTask?.value

        guard case .loaded(let lesson) = vm.viewState else {
            XCTFail("viewState가 .loaded여야 합니다. 실제: \(vm.viewState)")
            return
        }
        XCTAssertEqual(lesson.level, 1)
        XCTAssertEqual(lesson.lessonNumber, 2)
        XCTAssertEqual(lesson.words.count, 15)
    }

    func test_load_이력_스트림이_값을_방출하면_learningHistory가_채워진다() async {
        let vm = withDependencies {
            $0.loadVocabularyListUseCase = .previewValue
            $0.learningHistoryRepository.stream = { _ in makeHistoryStream([.preview]) }
        } operation: {
            VocabularyListViewModel(lessonID: "t")
        }

        await vm.load()
        await vm.historyObservationTask?.value

        XCTAssertEqual(vm.learningHistory, .preview)
    }

    func test_load_이력_스트림이_값을_안_주면_learningHistory는_nil로_남는다() async {
        let vm = withDependencies {
            $0.loadVocabularyListUseCase = .previewValue
            $0.learningHistoryRepository.stream = { _ in makeHistoryStream([]) }
        } operation: {
            VocabularyListViewModel(lessonID: "t")
        }

        await vm.load()
        await vm.historyObservationTask?.value

        XCTAssertNil(vm.learningHistory)
    }

    func test_load_2회_호출해도_이력_구독은_1번만_실행된다() async {
        let historyCounter = CallCounter()
        let vm = withDependencies {
            $0.loadVocabularyListUseCase = .previewValue
            $0.learningHistoryRepository.stream = { _ in
                historyCounter.increment()
                return makeHistoryStream([])
            }
        } operation: {
            VocabularyListViewModel(lessonID: "t")
        }

        await vm.load()
        await vm.historyObservationTask?.value
        await vm.load()
        await vm.historyObservationTask?.value

        XCTAssertEqual(historyCounter.value, 1)
    }

    func test_didTapWord_잘못된ID_호출시_destination이_nil이다() async {
        let vm = withDependencies {
            $0.loadVocabularyListUseCase = .previewValue
            $0.learningHistoryRepository.stream = { _ in makeHistoryStream([]) }
        } operation: {
            VocabularyListViewModel(lessonID: "t")
        }

        await vm.load()
        vm.didTapWord(id: "존재하지_않는_id")

        XCTAssertNil(vm.destination)
    }

    func test_didTapWord_정상ID_호출시_destination이_wordDetail로_설정된다() async {
        let vm = withDependencies {
            $0.loadVocabularyListUseCase = .previewValue
            $0.learningHistoryRepository.stream = { _ in makeHistoryStream([]) }
        } operation: {
            VocabularyListViewModel(lessonID: "t")
        }

        await vm.load()
        vm.didTapWord(id: "word_001")

        guard case .wordDetail = vm.destination else {
            XCTFail("destination이 .wordDetail이어야 합니다. 실제: \(String(describing: vm.destination))")
            return
        }
    }
}

private enum MockError: Error {
    case stub
}

private func makeHistoryStream(_ values: [LearningHistory]) -> AsyncStream<LearningHistory> {
    AsyncStream { continuation in
        for value in values { continuation.yield(value) }
        continuation.finish()
    }
}

/// 테스트 전용 — 의존성 클로저가 몇 번 호출됐는지 세기 위한 카운터.
private final class CallCounter: @unchecked Sendable {
    private(set) var value = 0
    func increment() { value += 1 }
}
