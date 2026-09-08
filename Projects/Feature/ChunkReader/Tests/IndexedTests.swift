import XCTest

@testable import FeatureChunkReader

final class IndexedTests: XCTestCase {
    func test_배열의_각_원소에_순서대로_id를_부여한다() {
        let items = ["a", "b", "c"].indexed()

        XCTAssertEqual(items.map(\.id), [0, 1, 2])
        XCTAssertEqual(items.map(\.element), ["a", "b", "c"])
    }

    func test_빈배열이면_빈배열을_반환한다() {
        let items = [String]().indexed()

        XCTAssertEqual(items, [])
    }
}
