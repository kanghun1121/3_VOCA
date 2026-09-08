import XCTest

@testable import FeatureWord
import DomainInterface

final class WordDetailDefinitionGroupingTests: XCTestCase {
    func test_정의가_없으면_빈배열을_반환한다() {
        let detail = makeWordDetail(definitions: [])

        XCTAssertEqual(detail.groupedDefinitions(), [])
    }

    func test_같은품사의_정의는_하나의그룹으로_묶인다() {
        let detail = makeWordDetail(definitions: [
            .init(meaning: "어두운", partOfSpeech: .adjective),
            .init(meaning: "우울한", partOfSpeech: .adjective)
        ])

        let groups = detail.groupedDefinitions()

        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].partOfSpeech, "형용사")
        XCTAssertEqual(groups[0].meanings, ["어두운", "우울한"])
    }

    func test_다른품사의_정의는_등장순서대로_별도그룹이_된다() {
        let detail = makeWordDetail(definitions: [
            .init(meaning: "어두운", partOfSpeech: .adjective),
            .init(meaning: "어둠", partOfSpeech: .noun)
        ])

        let groups = detail.groupedDefinitions()

        XCTAssertEqual(groups.map(\.partOfSpeech), ["형용사", "명사"])
    }
}

private func makeWordDetail(definitions: [WordDetail.Definition]) -> WordDetail {
    WordDetail(
        id: "word_1",
        term: "dark",
        level: 1,
        pronunciation: "/dɑːrk/",
        definitions: definitions,
        examples: []
    )
}
