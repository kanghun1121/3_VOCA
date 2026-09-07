import XCTest

import DomainInterface
@testable import Data

final class EntitiesMappingTests: XCTestCase {
    func test_pos가_PartOfSpeech에_있으면_그대로_매핑된다() {
        let meaning = WordMeaningEntity(id: 1, wordID: 1, pos: "noun", ko: "테스트", rank: 1)

        XCTAssertEqual(meaning.toWordDetailDefinition().partOfSpeech, .noun)
        XCTAssertEqual(meaning.toLessonWordDefinition().partOfSpeech, .noun)
    }

    func test_pos가_PartOfSpeech에_없으면_unknown으로_폴백한다() {
        // "article"/"determiner"는 실제 시드 데이터에 존재하지만 PartOfSpeech enum에는 없다.
        let meaning = WordMeaningEntity(id: 1, wordID: 1, pos: "article", ko: "테스트", rank: 1)

        XCTAssertEqual(meaning.toWordDetailDefinition().partOfSpeech, .unknown)
        XCTAssertEqual(meaning.toLessonWordDefinition().partOfSpeech, .unknown)
    }

    func test_예문의_words_chunks가_비어있으면_도메인에서_nil로_변환된다() {
        let example = WordExampleEntity(
            id: 1,
            wordID: 1,
            order: 1,
            sentenceEn: "en",
            sentenceKo: "ko",
            words: [],
            chunks: []
        )

        let domain = example.toWordDetailExample()

        XCTAssertNil(domain.words)
        XCTAssertNil(domain.chunks)
    }

    func test_예문의_words_chunks가_있으면_그대로_변환된다() {
        let example = WordExampleEntity(
            id: 1,
            wordID: 1,
            order: 1,
            sentenceEn: "en",
            sentenceKo: "ko",
            words: [ExampleWordPayload(word: "apple", pos: "noun", meaning: "사과")],
            chunks: [ExampleChunkPayload(text: "an apple", meaning: "사과 하나")]
        )

        let domain = example.toWordDetailExample()

        XCTAssertEqual(domain.words?.map(\.word), ["apple"])
        XCTAssertEqual(domain.chunks?.map(\.text), ["an apple"])
    }
}
