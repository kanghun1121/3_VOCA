import XCTest

@testable import FeatureLesson
import DomainInterface

final class LevelSummaryStatusTests: XCTestCase {
    func test_completedLessons가_0이면_notStarted다() {
        let level = makeLevel(completedLessons: 0, totalLessons: 10)

        XCTAssertEqual(level.status, .notStarted)
    }

    func test_completedLessons가_totalLessons보다_작으면_active다() {
        let level = makeLevel(completedLessons: 3, totalLessons: 10)

        XCTAssertEqual(level.status, .active)
    }

    func test_completedLessons가_totalLessons와_같으면_completed다() {
        let level = makeLevel(completedLessons: 10, totalLessons: 10)

        XCTAssertEqual(level.status, .completed)
    }

    func test_totalLessons가_0이고_completedLessons도_0이면_notStarted이며_progressRatio는_0이다() {
        let level = makeLevel(completedLessons: 0, totalLessons: 0)

        XCTAssertEqual(level.status, .notStarted)
        XCTAssertEqual(level.progressRatio, 0)
    }

    func test_progressRatio는_completedLessons_나누기_totalLessons다() {
        let level = makeLevel(completedLessons: 3, totalLessons: 10)

        XCTAssertEqual(level.progressRatio, 0.3, accuracy: 0.0001)
    }
}

private func makeLevel(completedLessons: Int, totalLessons: Int) -> LevelSummary {
    LevelSummary(
        id: "level_1",
        level: 1,
        name: "Level 1",
        difficulty: "A1",
        totalLessons: totalLessons,
        completedLessons: completedLessons,
        lessons: []
    )
}
