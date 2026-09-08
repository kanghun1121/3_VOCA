import XCTest

@testable import FeatureWord
import DomainInterface

final class WordDetailExampleSortingTests: XCTestCase {
    func test_sortedExamples는_order_오름차순으로_정렬한다() {
        let detail = makeWordDetail(examples: [
            .init(en: "second", ko: "두번째", order: 2),
            .init(en: "first", ko: "첫번째", order: 1)
        ])

        XCTAssertEqual(detail.sortedExamples.map(\.order), [1, 2])
        XCTAssertEqual(detail.sortedExamples.map(\.en), ["first", "second"])
    }

    func test_examples가_비어있으면_sortedExamples도_비어있다() {
        let detail = makeWordDetail(examples: [])

        XCTAssertEqual(detail.sortedExamples, [])
    }

    func test_Example의_id는_order와_같다() {
        let example = WordDetail.Example(en: "en", ko: "ko", order: 7)

        XCTAssertEqual(example.id, 7)
    }
}

private func makeWordDetail(examples: [WordDetail.Example]) -> WordDetail {
    WordDetail(
        id: "word_1",
        term: "dark",
        level: 1,
        pronunciation: "/dɑːrk/",
        definitions: [],
        examples: examples
    )
}
