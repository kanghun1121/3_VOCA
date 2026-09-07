import XCTest

@testable import Data

/// "디스크엔 파일을 뒀는데 Project.swift 글롭에 안 걸림" 같은 실수를 잡는 스모크 테스트.
final class LocalDatabaseSeedResourcesTests: XCTestCase {
    func test_시드_JSON_7개가_전부_번들에_포함되어_있다() {
        let names = ["levels", "lessons", "lesson_words", "words", "word_meanings", "word_examples", "distractors"]

        for name in names {
            XCTAssertNotNil(
                Bundle.module.url(forResource: name, withExtension: "json"),
                "\(name).json이 번들 리소스에 없음"
            )
        }
    }
}
