import XCTest

import NetworkingInterface

@testable import Data

final class ChatProxyRequestTests: XCTestCase {
    private func makeSUT(
        message: String = "hello",
        sseID: String = "sse-001",
        wordID: String? = "word_766",
        conversationID: String? = nil,
        accessToken: String? = nil
    ) -> ChatProxyRequest {
        ChatProxyRequest(
            messages: [ChatProxyMessage(role: "user", content: message)],
            sseID: sseID,
            wordID: wordID,
            conversationID: conversationID,
            accessToken: accessToken
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

    func test_body는_model_maxTokens없이_stream_messages만_인코딩한다() throws {
        let sut = makeSUT(message: "hello")

        let request = try sut.makeURLRequest()
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertNil(json["model"])
        XCTAssertNil(json["max_tokens"])
        XCTAssertEqual(json["stream"] as? Bool, true)

        let messages = try XCTUnwrap(json["messages"] as? [[String: String]])
        XCTAssertEqual(messages, [["role": "user", "content": "hello"]])
    }

    func test_body에_word_id가_포함된다() throws {
        let sut = makeSUT(wordID: "word_766")

        let request = try sut.makeURLRequest()
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(json["word_id"] as? String, "word_766")
    }

    func test_body에_sse_id가_포함된다() throws {
        let sut = makeSUT(sseID: "sse-abc")

        let request = try sut.makeURLRequest()
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(json["sse_id"] as? String, "sse-abc")
    }

    func test_conversationID가_있으면_conversation_id가_실리고_word_id는_보내지_않는다() throws {
        let sut = makeSUT(wordID: nil, conversationID: "conv-001")

        let request = try sut.makeURLRequest()
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(json["conversation_id"] as? String, "conv-001")
        XCTAssertNil(json["word_id"])
    }

    func test_conversationID가_없으면_conversation_id_키_자체가_없다() throws {
        let sut = makeSUT(wordID: "word_766", conversationID: nil)

        let request = try sut.makeURLRequest()
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertNil(json["conversation_id"])
    }

    func test_accessToken이_있으면_Authorization_헤더에_Bearer로_실린다() throws {
        let sut = makeSUT(accessToken: "test-token")

        let request = try sut.makeURLRequest()

        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
    }

    func test_accessToken이_없으면_Authorization_헤더가_없다() throws {
        let sut = makeSUT(accessToken: nil)

        let request = try sut.makeURLRequest()

        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
    }

    func test_accessToken이_있어도_Content_Type_헤더는_그대로_유지된다() throws {
        let sut = makeSUT(accessToken: "test-token")

        let request = try sut.makeURLRequest()

        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }
}
