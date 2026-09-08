import XCTest

import DomainInterface

final class LessonWordPrimaryMeaningTests: XCTestCase {
    func test_정의가_있으면_첫번째_정의의_뜻을_반환한다() {
        let word = makeWord(definitions: [
            .init(id: "d1", partOfSpeech: .adjective, meaning: "모호한"),
            .init(id: "d2", partOfSpeech: .noun, meaning: "애매함")
        ])

        XCTAssertEqual(word.primaryMeaning, "모호한")
    }

    func test_정의가_없으면_빈문자열을_반환한다() {
        let word = makeWord(definitions: [])

        XCTAssertEqual(word.primaryMeaning, "")
    }
}

private func makeWord(definitions: [Lesson.Word.Definition]) -> Lesson.Word {
    Lesson.Word(
        id: "word_1",
        term: "ambiguous",
        pronunciation: "/æmˈbɪɡjuəs/",
        definitions: definitions,
        distractors: [],
        audioUrl: ""
    )
}
