import XCTest

@testable import FeatureHome
import DomainInterface

final class SessionProgressCellStatusTests: XCTestCase {
    func test_빈배열이면_빈배열을_반환한다() {
        let sessions: [SessionProgress] = []

        XCTAssertEqual(sessions.cellStatuses, [])
    }

    func test_완료된세션은_done이고_완료되지않은_첫세션은_current이며_나머지는_todo다() {
        let sessions = [
            makeSession(status: .completed),
            makeSession(status: .notStarted),
            makeSession(status: .notStarted)
        ]

        XCTAssertEqual(sessions.cellStatuses, [.done, .current, .todo])
    }

    func test_모두_완료된세션이면_current없이_전부_done이다() {
        let sessions = [
            makeSession(status: .completed),
            makeSession(status: .completed)
        ]

        XCTAssertEqual(sessions.cellStatuses, [.done, .done])
    }

    func test_단일_미완료세션은_current다() {
        let sessions = [makeSession(status: .notStarted)]

        XCTAssertEqual(sessions.cellStatuses, [.current])
    }
}

private func makeSession(status: SessionProgressStatus) -> SessionProgress {
    SessionProgress(
        id: "1",
        sessionNumber: 1,
        totalWords: 20,
        status: status,
        lastStudiedAt: nil,
        accuracy: nil,
        wordsCompleted: 0
    )
}
