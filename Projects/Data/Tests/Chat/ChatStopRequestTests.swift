import XCTest

import NetworkingInterface

@testable import Data

final class ChatStopRequestTests: XCTestCase {
    private func makeSUT(sseID: String = "sse-001") -> ChatStopRequest {
        ChatStopRequest(sseID: sseID)
    }

    func test_makeURLRequest가_만든_최종_URL은_chat_stop_함수_경로다() throws {
        let sut = makeSUT()

        let request = try sut.makeURLRequest()

        XCTAssertEqual(request.url, URL(string: "https://ebvfeuopuzlpddzvcini.supabase.co/functions/v1/chat-stop")!)
    }

    func test_method는_POST다() throws {
        let sut = makeSUT()

        let request = try sut.makeURLRequest()

        XCTAssertEqual(request.httpMethod, "POST")
    }

    func test_body에_sse_id가_포함된다() throws {
        let sut = makeSUT(sseID: "sse-xyz")

        let request = try sut.makeURLRequest()
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(json["sse_id"] as? String, "sse-xyz")
    }

    func test_requiresAuthentication은_기본값_true다() {
        let sut = makeSUT()

        XCTAssertTrue(sut.requiresAuthentication)
    }
}
