import XCTest

import DomainInterface
@testable import FeatureHome

import Dependencies

@MainActor
final class HomeViewModelLoadTests: XCTestCase {
    func test_초기값은_기록이_비어있다() {
        let vm = withDependencies {
            $0.learningHistoryRepository = .previewValue
        } operation: {
            HomeViewModel()
        }

        XCTAssertEqual(vm.selectedDayRecords, [])
    }

    func test_onAppear_성공시_해당_날짜의_기록이_채워진다() async {
        let vm = withDependencies {
            $0.learningHistoryRepository.streamAllCompletions = { makeStream([[.previewFixture]]) }
        } operation: {
            HomeViewModel()
        }

        await vm.onAppear()
        await vm.observationTask?.value

        XCTAssertEqual(vm.selectedDayRecords.map(\.lessonID), [LessonCompletionRecord.previewFixture.lessonID])
    }

    func test_onAppear_완료_기록이_비어있어도_selectedDayRecords는_빈_배열이다() async {
        // 완료 기록이 없어도 캘린더 화면 자체는 항상 보여야 한다 — "기록 없음"은
        // 화면 전체 전환이 아니라 선택된 날짜의 상태로만 표현된다.
        let vm = withDependencies {
            $0.learningHistoryRepository.streamAllCompletions = { makeStream([[]]) }
        } operation: {
            HomeViewModel()
        }

        await vm.onAppear()
        await vm.observationTask?.value

        XCTAssertEqual(vm.selectedDayRecords, [])
    }

    func test_onAppear_스트림이_값을_안_주면_기록도_비어있는_채로_유지된다() async {
        let vm = withDependencies {
            $0.learningHistoryRepository.streamAllCompletions = { makeStream([]) }
        } operation: {
            HomeViewModel()
        }

        await vm.onAppear()
        await vm.observationTask?.value

        XCTAssertEqual(vm.selectedDayRecords, [])
    }

    func test_스트림이_값을_2번_주면_최신_값이_반영된다() async {
        let first = [makeRecord(lessonID: "1")]
        let second = [makeRecord(lessonID: "2")]
        let vm = withDependencies {
            $0.learningHistoryRepository.streamAllCompletions = { makeStream([first, second]) }
        } operation: {
            HomeViewModel()
        }

        await vm.onAppear()
        await vm.observationTask?.value

        XCTAssertEqual(vm.selectedDayRecords.map(\.lessonID), ["2"])
    }

    func test_onAppear_2회_호출해도_구독_스트림은_1번만_생성된다() async {
        let counter = CallCounter()
        let vm = withDependencies {
            $0.learningHistoryRepository.streamAllCompletions = {
                counter.increment()
                return makeStream([[.previewFixture]])
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

/// 테스트 전용 — `streamAllCompletions`이 몇 번 호출됐는지 세기 위한 카운터.
private final class CallCounter: @unchecked Sendable {
    private(set) var value = 0
    func increment() { value += 1 }
}

private func makeStream(_ values: [[LessonCompletionRecord]]) -> AsyncStream<[LessonCompletionRecord]> {
    AsyncStream { continuation in
        for value in values { continuation.yield(value) }
        continuation.finish()
    }
}

private func makeRecord(lessonID: String) -> LessonCompletionRecord {
    LessonCompletionRecord(
        lessonID: lessonID,
        levelName: "Level 1",
        lessonNumber: 1,
        totalWords: 10,
        lastStudiedAt: .now
    )
}
