import XCTest

import NetworkingInterface

@testable import Data

final class ChatProxyRequestTests: XCTestCase {
    private func makeSUT(message: String = "hello") -> ChatProxyRequest {
        ChatProxyRequest(
            model: "claude-sonnet-5",
            maxTokens: 2048,
            messages: [ChatProxyMessage(role: "user", content: message)]
        )
    }

    func test_baseURL은_Supabase_함수_URL이다() {
        let sut = makeSUT()

        XCTAssertEqual(sut.baseURL, URL(string: "https://ebvfeuopuzlpddzvcini.supabase.co")!)
    }

    func test_makeURLRequest가_만든_최종_URL은_chat_함수_경로다() throws {
        let sut = makeSUT()

        let request = try sut.makeURLRequest()

        XCTAssertEqual(request.url, URL(string: "https://ebvfeuopuzlpddzvcini.supabase.co/functions/v1/chat")!)
    }

    func test_x_api_key와_anthropic_version_헤더가_없다() throws {
        let sut = makeSUT()

        let request = try sut.makeURLRequest()

        XCTAssertNil(request.value(forHTTPHeaderField: "x-api-key"))
        XCTAssertNil(request.value(forHTTPHeaderField: "anthropic-version"))
    }

    func test_Content_Type은_json_body에_의해_자동으로_부착된다() throws {
        let sut = makeSUT()

        let request = try sut.makeURLRequest()

        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }

    func test_body는_model_maxTokens_stream_messages를_그대로_인코딩한다() throws {
        let sut = makeSUT(message: "hello")

        let request = try sut.makeURLRequest()
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(json["model"] as? String, "claude-sonnet-5")
        XCTAssertEqual(json["max_tokens"] as? Int, 2048)
        XCTAssertEqual(json["stream"] as? Bool, true)

        let messages = try XCTUnwrap(json["messages"] as? [[String: String]])
        XCTAssertEqual(messages, [["role": "user", "content": "hello"]])
    }
}
