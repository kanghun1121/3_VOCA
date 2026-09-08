import XCTest

import DomainInterface
@testable import FeatureLesson

import Dependencies

@MainActor
final class LearningLibraryViewModelTests: XCTestCase {
    func test_초기값은_loading이다() {
        let vm = withDependencies {
            $0.learningLibraryRepository = .previewValue
        } operation: {
            LearningLibraryViewModel()
        }

        XCTAssertEqual(vm.uiState, .loading)
    }

    func test_onAppear_성공시_uiState가_success로_채워지고_활성_레벨이_최초_펼쳐진다() async {
        let library = makeLibrary(levels: [
            makeLevel(id: "level_1", completedLessons: 5, totalLessons: 5), // completed
            makeLevel(id: "level_2", completedLessons: 2, totalLessons: 5), // active
            makeLevel(id: "level_3", completedLessons: 0, totalLessons: 5), // notStarted
        ])
        let vm = withDependencies {
            $0.learningLibraryRepository.stream = { makeStream([library]) }
        } operation: {
            LearningLibraryViewModel()
        }

        await vm.onAppear()
        await vm.observationTask?.value

        XCTAssertEqual(vm.uiState, .success(library))
        XCTAssertEqual(vm.expandedLevelIDs, ["level_2"])
    }

    func test_이미_펼친_레벨이_있으면_활성_레벨_자동_삽입을_하지_않는다() async {
        let library = makeLibrary(levels: [
            makeLevel(id: "level_1", completedLessons: 2, totalLessons: 5), // active
        ])
        let vm = withDependencies {
            $0.learningLibraryRepository.stream = { makeStream([library]) }
        } operation: {
            LearningLibraryViewModel()
        }
        vm.didTapLevel(id: "level_manual")

        await vm.onAppear()
        await vm.observationTask?.value

        XCTAssertEqual(vm.expandedLevelIDs, ["level_manual"])
    }

    func test_스트림이_값을_안_주면_uiState는_loading에_머무른다() async {
        let vm = withDependencies {
            $0.learningLibraryRepository.stream = { makeStream([]) }
        } operation: {
            LearningLibraryViewModel()
        }

        await vm.onAppear()
        await vm.observationTask?.value

        XCTAssertEqual(vm.uiState, .loading)
    }

    func test_onAppear_2회_호출해도_구독_스트림은_1번만_생성된다() async {
        let counter = CallCounter()
        let vm = withDependencies {
            $0.learningLibraryRepository.stream = {
                counter.increment()
                return makeStream([.previewFixture])
            }
        } operation: {
            LearningLibraryViewModel()
        }

        await vm.onAppear()
        await vm.observationTask?.value
        await vm.onAppear()
        await vm.observationTask?.value

        XCTAssertEqual(counter.value, 1)
    }

    func test_스트림이_값을_2번_주면_최신_값으로_갱신되고_expandedLevelIDs는_유지된다() async {
        let first = makeLibrary(levels: [
            makeLevel(id: "level_1", completedLessons: 2, totalLessons: 5), // active
        ])
        let second = makeLibrary(levels: [
            makeLevel(id: "level_2", completedLessons: 3, totalLessons: 5), // active
        ])
        let vm = withDependencies {
            $0.learningLibraryRepository.stream = { makeStream([first, second]) }
        } operation: {
            LearningLibraryViewModel()
        }

        await vm.onAppear()
        await vm.observationTask?.value

        XCTAssertEqual(vm.uiState, .success(second))
        XCTAssertEqual(vm.expandedLevelIDs, ["level_1"])
    }
}

/// 테스트 전용 — `stream`이 몇 번 호출됐는지 세기 위한 카운터.
private final class CallCounter: @unchecked Sendable {
    private(set) var value = 0
    func increment() { value += 1 }
}

private func makeStream(_ values: [LearningLibrary]) -> AsyncStream<LearningLibrary> {
    AsyncStream { continuation in
        for value in values { continuation.yield(value) }
        continuation.finish()
    }
}

private func makeLibrary(levels: [LevelSummary]) -> LearningLibrary {
    LearningLibrary(levels: levels)
}

private func makeLevel(
    id: String,
    completedLessons: Int,
    totalLessons: Int
) -> LevelSummary {
    LevelSummary(
        id: id,
        level: 1,
        name: "Level",
        difficulty: "A1",
        totalLessons: totalLessons,
        completedLessons: completedLessons,
        lessons: []
    )
}
