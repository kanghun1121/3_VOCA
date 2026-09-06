import XCTest

import DomainInterface
@testable import FeatureLesson

import Dependencies

@MainActor
final class LessonDetailViewModelTests: XCTestCase {
    func test_onAppear_콘텐츠_조회_성공시_uiState가_loaded로_전환된다() async {
        let vm = withDependencies {
            $0.loadLessonDetailUseCase.execute = { id in (lesson: .preview(id: id), audioReady: Task {}) }
            $0.learningHistoryRepository.stream = { _ in makeHistoryStream([]) }
        } operation: {
            LessonDetailViewModel(lessonID: "t")
        }

        await vm.onAppear()
        await vm.historyObservationTask?.value

        guard case .loaded = vm.uiState else {
            XCTFail("uiState가 .loaded여야 합니다. 실제: \(vm.uiState)")
            return
        }
    }

    func test_onAppear_콘텐츠_조회_실패시_uiState가_error로_전환된다() async {
        let vm = withDependencies {
            $0.loadLessonDetailUseCase.execute = { _ in throw MockError.stub }
            $0.learningHistoryRepository.stream = { _ in makeHistoryStream([]) }
        } operation: {
            LessonDetailViewModel(lessonID: "t")
        }

        await vm.onAppear()
        await vm.historyObservationTask?.value

        guard case .error = vm.uiState else {
            XCTFail("uiState가 .error여야 합니다. 실제: \(vm.uiState)")
            return
        }
    }

    func test_onAppear_이력_스트림이_값을_방출하면_learningHistory가_채워진다() async {
        let vm = withDependencies {
            $0.loadLessonDetailUseCase.execute = { id in (lesson: .preview(id: id), audioReady: Task {}) }
            $0.learningHistoryRepository.stream = { _ in makeHistoryStream([.preview]) }
        } operation: {
            LessonDetailViewModel(lessonID: "t")
        }

        await vm.onAppear()
        await vm.historyObservationTask?.value

        XCTAssertEqual(vm.learningHistory, .preview)
    }

    func test_onAppear_이력_스트림이_값을_안_주면_learningHistory는_nil로_남는다() async {
        let vm = withDependencies {
            $0.loadLessonDetailUseCase.execute = { id in (lesson: .preview(id: id), audioReady: Task {}) }
            $0.learningHistoryRepository.stream = { _ in makeHistoryStream([]) }
        } operation: {
            LessonDetailViewModel(lessonID: "t")
        }

        await vm.onAppear()
        await vm.historyObservationTask?.value

        XCTAssertNil(vm.learningHistory)
    }

    func test_onAppear_2회_호출해도_콘텐츠_조회와_이력_구독은_1번만_실행된다() async {
        let contentCounter = CallCounter()
        let historyCounter = CallCounter()
        let vm = withDependencies {
            $0.loadLessonDetailUseCase.execute = { id in
                contentCounter.increment()
                return (lesson: .preview(id: id), audioReady: Task {})
            }
            $0.learningHistoryRepository.stream = { _ in
                historyCounter.increment()
                return makeHistoryStream([])
            }
        } operation: {
            LessonDetailViewModel(lessonID: "t")
        }

        await vm.onAppear()
        await vm.historyObservationTask?.value
        await vm.onAppear()
        await vm.historyObservationTask?.value

        XCTAssertEqual(contentCounter.value, 1)
        XCTAssertEqual(historyCounter.value, 1)
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
