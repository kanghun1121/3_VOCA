import XCTest

@testable import FeatureLesson
import DomainInterface

final class LessonProgressCellStatusTests: XCTestCase {
    func test_빈배열이면_빈배열을_반환한다() {
        let lessons: [LessonProgress] = []

        XCTAssertEqual(lessons.cellStatuses, [])
    }

    func test_완료된레슨은_done이고_완료되지않은_첫레슨은_current이며_나머지는_todo다() {
        let lessons = [
            makeLesson(status: .completed),
            makeLesson(status: .notStarted),
            makeLesson(status: .notStarted)
        ]

        XCTAssertEqual(lessons.cellStatuses, [.done, .current, .todo])
    }

    func test_모두_완료된레슨이면_current없이_전부_done이다() {
        let lessons = [
            makeLesson(status: .completed),
            makeLesson(status: .completed)
        ]

        XCTAssertEqual(lessons.cellStatuses, [.done, .done])
    }

    func test_단일_미완료레슨은_current다() {
        let lessons = [makeLesson(status: .notStarted)]

        XCTAssertEqual(lessons.cellStatuses, [.current])
    }
}

private func makeLesson(status: LessonProgressStatus) -> LessonProgress {
    LessonProgress(
        id: "1",
        lessonNumber: 1,
        totalWords: 20,
        status: status,
        lastStudiedAt: nil,
        accuracy: nil,
        wordsCompleted: 0
    )
}
