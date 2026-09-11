import XCTest

import NetworkingInterface

@testable import Data

final class ChatHistoryRequestTests: XCTestCase {
    private func makeSUT(wordID: String = "word_766") -> ChatHistoryRequest {
        ChatHistoryRequest(wordID: wordID)
    }

    func test_method은_GET이다() {
        let sut = makeSUT()

        XCTAssertEqual(sut.method, .get)
    }

    func test_makeURLRequest가_만든_최종_URL은_chat_함수_경로에_word_id_쿼리를_포함한다() throws {
        let sut = makeSUT(wordID: "word_766")

        let request = try sut.makeURLRequest()

        XCTAssertEqual(
            request.url,
            URL(string: "https://ebvfeuopuzlpddzvcini.supabase.co/functions/v1/chat?word_id=word_766")!
        )
    }

    func test_requiresAuthentication은_기본값_true다() {
        let sut = makeSUT()

        XCTAssertTrue(sut.requiresAuthentication)
    }
}
