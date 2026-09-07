import XCTest

import DomainInterface
@testable import FeatureHome

import Dependencies

@MainActor
final class HomeViewModelSelectedDateTests: XCTestCase {
    private var cal: Calendar { .current }
    private var today: Date { cal.startOfDay(for: .now) }

    func test_isSelectedDateFuture_선택한_날짜가_미래면_true다() {
        let vm = HomeViewModel(today: today)
        let tomorrow = cal.date(byAdding: .day, value: 1, to: today)!

        vm.didTapDate(tomorrow)

        XCTAssertTrue(vm.isSelectedDateFuture)
    }

    func test_isSelectedDateFuture_선택한_날짜가_오늘이면_false다() {
        let vm = HomeViewModel(today: today)

        vm.didTapDate(today)

        XCTAssertFalse(vm.isSelectedDateFuture)
    }

    func test_isSelectedDateFuture_선택한_날짜가_과거면_false다() {
        let vm = HomeViewModel(today: today)
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!

        vm.didTapDate(yesterday)

        XCTAssertFalse(vm.isSelectedDateFuture)
    }

    func test_selectedDayRecords_기록이_있는_날짜를_선택하면_해당_배열을_반환한다() async {
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        // lastStudiedAt은 어제 오후 3시 — startOfDay 정규화로 어제 "하루" 전체에 매칭돼야 한다.
        let studiedAt = cal.date(byAdding: .hour, value: 15, to: yesterday)!
        let records = [
            LessonCompletionRecord(
                lessonID: "session_1",
                levelName: "Level 1",
                lessonNumber: 1,
                totalWords: 10,
                lastStudiedAt: studiedAt
            ),
        ]

        let vm = withDependencies {
            $0.learningHistoryRepository.streamAllCompletions = {
                AsyncStream { continuation in
                    continuation.yield(records)
                    continuation.finish()
                }
            }
        } operation: {
            HomeViewModel(today: today)
        }
        await vm.onAppear()
        await vm.observationTask?.value

        // 선택은 어제 오전 9시 — 저장된 시각(오후 3시)과 시:분은 다르지만 같은 날이므로 매칭돼야 한다.
        vm.didTapDate(cal.date(byAdding: .hour, value: 9, to: yesterday)!)

        XCTAssertEqual(vm.selectedDayRecords.map(\.lessonID), ["session_1"])
    }

    func test_selectedDayRecords_기록이_없는_날짜를_선택하면_빈_배열을_반환한다() async {
        let vm = withDependencies {
            $0.learningHistoryRepository = .previewValue
        } operation: {
            HomeViewModel(today: today)
        }
        await vm.onAppear()
        await vm.observationTask?.value

        let farFuture = cal.date(byAdding: .year, value: 1, to: today)!
        vm.didTapDate(farFuture)

        XCTAssertEqual(vm.selectedDayRecords, [])
    }
}
