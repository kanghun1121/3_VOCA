import XCTest

import DomainInterface
@testable import FeatureHome

import Dependencies

@MainActor
final class LevelLibraryViewModelTests: XCTestCase {
    func test_초기값은_loading이다() {
        let vm = withDependencies {
            $0.vocabularyLibraryRepository = .previewValue
        } operation: {
            LevelLibraryViewModel()
        }

        XCTAssertEqual(vm.uiState, .loading)
    }

    func test_onAppear_성공시_uiState가_success로_채워지고_활성_레벨이_최초_펼쳐진다() async {
        let library = makeLibrary(levels: [
            makeLevel(id: "level_1", completedSessions: 5, totalSessions: 5), // completed
            makeLevel(id: "level_2", completedSessions: 2, totalSessions: 5), // active
            makeLevel(id: "level_3", completedSessions: 0, totalSessions: 5), // notStarted
        ])
        let vm = withDependencies {
            $0.vocabularyLibraryRepository.stream = { makeStream([library]) }
        } operation: {
            LevelLibraryViewModel()
        }

        await vm.onAppear()
        await vm.observationTask?.value

        XCTAssertEqual(vm.uiState, .success(library))
        XCTAssertEqual(vm.expandedLevelIDs, ["level_2"])
    }

    func test_이미_펼친_레벨이_있으면_활성_레벨_자동_삽입을_하지_않는다() async {
        let library = makeLibrary(levels: [
            makeLevel(id: "level_1", completedSessions: 2, totalSessions: 5), // active
        ])
        let vm = withDependencies {
            $0.vocabularyLibraryRepository.stream = { makeStream([library]) }
        } operation: {
            LevelLibraryViewModel()
        }
        vm.didTapLevel(id: "level_manual")

        await vm.onAppear()
        await vm.observationTask?.value

        XCTAssertEqual(vm.expandedLevelIDs, ["level_manual"])
    }

    func test_스트림이_값을_안_주면_uiState는_loading에_머무른다() async {
        let vm = withDependencies {
            $0.vocabularyLibraryRepository.stream = { makeStream([]) }
        } operation: {
            LevelLibraryViewModel()
        }

        await vm.onAppear()
        await vm.observationTask?.value

        XCTAssertEqual(vm.uiState, .loading)
    }

    func test_onAppear_2회_호출해도_구독_스트림은_1번만_생성된다() async {
        let counter = CallCounter()
        let vm = withDependencies {
            $0.vocabularyLibraryRepository.stream = {
                counter.increment()
                return makeStream([.previewFixture])
            }
        } operation: {
            LevelLibraryViewModel()
        }

        await vm.onAppear()
        await vm.observationTask?.value
        await vm.onAppear()
        await vm.observationTask?.value

        XCTAssertEqual(counter.value, 1)
    }

    func test_스트림이_값을_2번_주면_최신_값으로_갱신되고_expandedLevelIDs는_유지된다() async {
        let first = makeLibrary(levels: [
            makeLevel(id: "level_1", completedSessions: 2, totalSessions: 5), // active
        ])
        let second = makeLibrary(levels: [
            makeLevel(id: "level_2", completedSessions: 3, totalSessions: 5), // active
        ])
        let vm = withDependencies {
            $0.vocabularyLibraryRepository.stream = { makeStream([first, second]) }
        } operation: {
            LevelLibraryViewModel()
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

private func makeStream(_ values: [VocabularyLibrary]) -> AsyncStream<VocabularyLibrary> {
    AsyncStream { continuation in
        for value in values { continuation.yield(value) }
        continuation.finish()
    }
}

private func makeLibrary(levels: [LevelSummary]) -> VocabularyLibrary {
    VocabularyLibrary(levels: levels)
}

private func makeLevel(
    id: String,
    completedSessions: Int,
    totalSessions: Int
) -> LevelSummary {
    LevelSummary(
        id: id,
        level: 1,
        name: "Level",
        difficulty: "A1",
        totalSessions: totalSessions,
        completedSessions: completedSessions,
        sessions: []
    )
}
