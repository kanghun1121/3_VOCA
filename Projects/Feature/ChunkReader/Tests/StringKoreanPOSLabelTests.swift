import XCTest

@testable import FeatureChunkReader

final class StringKoreanPOSLabelTests: XCTestCase {
    func test_알려진_품사코드는_한글라벨로_변환된다() {
        XCTAssertEqual("n".koreanPartOfSpeechLabel, "명사")
        XCTAssertEqual("v".koreanPartOfSpeechLabel, "동사")
        XCTAssertEqual("adj".koreanPartOfSpeechLabel, "형용사")
    }

    func test_대소문자와_무관하게_매칭된다() {
        XCTAssertEqual("N".koreanPartOfSpeechLabel, "명사")
    }

    func test_알수없는_코드는_원문그대로_반환한다() {
        XCTAssertEqual("xyz".koreanPartOfSpeechLabel, "xyz")
    }
}
