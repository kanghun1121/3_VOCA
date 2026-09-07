import Foundation

import NetworkingInterface

import Dependencies

/// Claude 메시지 API를 SSE로 스트리밍해 이벤트 시퀀스로 해석하는 계층. 로컬 저장 요소가
/// 전혀 없는 도메인이라(스트림 결과를 즉시 소비하고 버림) LocalDataSource는 만들지 않는다.
struct ChatBotRemoteDataSource: Sendable {
    private static let model = "claude-sonnet-5"
    private static let maxTokens = 2048

    func streamEvents(message: String) -> AsyncThrowingStream<ClaudeMessageStreamResponse, Error> {
        @Dependency(\.sseClient) var sseClient
        let request = ClaudeMessagesRequest(
            model: Self.model,
            maxTokens: Self.maxTokens,
            messages: [ClaudeChatMessage(role: "user", content: message)]
        )
        return ClaudeSSEParser.parse(frames: sseClient.stream(request))
    }
}

extension ChatBotRemoteDataSource: DependencyKey {
    static let liveValue = ChatBotRemoteDataSource()
}

extension ChatBotRemoteDataSource: TestDependencyKey {
    static let testValue = ChatBotRemoteDataSource()
}

extension DependencyValues {
    var chatBotRemoteDataSource: ChatBotRemoteDataSource {
        get { self[ChatBotRemoteDataSource.self] }
        set { self[ChatBotRemoteDataSource.self] = newValue }
    }
}
