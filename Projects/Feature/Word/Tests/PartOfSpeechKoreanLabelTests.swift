import XCTest

@testable import FeatureWord
import DomainInterface

final class PartOfSpeechKoreanLabelTests: XCTestCase {
    func test_9개_품사_라벨이_모두_한글로_변환된다() {
        XCTAssertEqual(PartOfSpeech.noun.koreanLabel, "명사")
        XCTAssertEqual(PartOfSpeech.verb.koreanLabel, "동사")
        XCTAssertEqual(PartOfSpeech.adjective.koreanLabel, "형용사")
        XCTAssertEqual(PartOfSpeech.adverb.koreanLabel, "부사")
        XCTAssertEqual(PartOfSpeech.preposition.koreanLabel, "전치사")
        XCTAssertEqual(PartOfSpeech.conjunction.koreanLabel, "접속사")
        XCTAssertEqual(PartOfSpeech.interjection.koreanLabel, "감탄사")
        XCTAssertEqual(PartOfSpeech.pronoun.koreanLabel, "대명사")
        XCTAssertEqual(PartOfSpeech.unknown.koreanLabel, "기타")
    }
}
