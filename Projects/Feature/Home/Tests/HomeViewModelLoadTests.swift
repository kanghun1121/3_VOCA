import XCTest

import DomainInterface
@testable import FeatureHome

import Dependencies

@MainActor
final class HomeViewModelLoadTests: XCTestCase {
    func test_초기값은_loading이다() {
        let vm = withDependencies {
            $0.vocabularyLibraryRepository = .previewValue
        } operation: {
            HomeViewModel()
        }

        XCTAssertEqual(vm.uiState, .loading)
    }

    func test_onAppear_성공시_uiState가_success로_채워진다() async {
        let vm = withDependencies {
            $0.vocabularyLibraryRepository.stream = { makeStream([.previewFixture]) }
        } operation: {
            HomeViewModel()
        }

        await vm.onAppear()
        await vm.observationTask?.value

        XCTAssertEqual(vm.uiState, .success(.previewFixture))
    }

    func test_onAppear_성공했지만_levels가_비어있으면_uiState가_empty가_된다() async {
        let vm = withDependencies {
            $0.vocabularyLibraryRepository.stream = { makeStream([VocabularyLibrary(levels: [])]) }
        } operation: {
            HomeViewModel()
        }

        await vm.onAppear()
        await vm.observationTask?.value

        XCTAssertEqual(vm.uiState, .empty)
    }

    func test_onAppear_스트림이_값을_안_주면_uiState는_loading에_머무른다() async {
        let vm = withDependencies {
            $0.vocabularyLibraryRepository.stream = { makeStream([]) }
        } operation: {
            HomeViewModel()
        }

        await vm.onAppear()
        await vm.observationTask?.value

        XCTAssertEqual(vm.uiState, .loading)
    }

    func test_스트림이_값을_2번_주면_최신_값이_uiState에_반영된다() async {
        let first = makeLibrary(levelID: "level_1")
        let second = makeLibrary(levelID: "level_2")
        let vm = withDependencies {
            $0.vocabularyLibraryRepository.stream = { makeStream([first, second]) }
        } operation: {
            HomeViewModel()
        }

        await vm.onAppear()
        await vm.observationTask?.value

        XCTAssertEqual(vm.uiState, .success(second))
    }

    func test_onAppear_2회_호출해도_구독_스트림은_1번만_생성된다() async {
        let counter = CallCounter()
        let vm = withDependencies {
            $0.vocabularyLibraryRepository.stream = {
                counter.increment()
                return makeStream([.previewFixture])
            }
        } operation: {
            HomeViewModel()
        }

        await vm.onAppear()
        await vm.observationTask?.value
        await vm.onAppear()
        await vm.observationTask?.value

        XCTAssertEqual(counter.value, 1)
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

private func makeLibrary(levelID: String) -> VocabularyLibrary {
    VocabularyLibrary(levels: [
        LevelSummary(
            id: levelID,
            level: 1,
            name: "Level 1",
            difficulty: "A1",
            totalSessions: 1,
            completedSessions: 0,
            sessions: []
        ),
    ])
}
