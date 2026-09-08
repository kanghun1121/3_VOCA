import Foundation

import NetworkingInterface

import Dependencies

/// Supabase Edge Function 챗봇 프록시를 SSE로 스트리밍해 이벤트 시퀀스로 해석하는 계층.
/// 프록시가 Claude Messages API 이벤트를 가공 없이 그대로 전달하므로 이벤트 스키마 해석은
/// 여전히 Claude 스키마 기준이다. 로컬 저장 요소가 전혀 없는 도메인이라(스트림 결과를 즉시
/// 소비하고 버림) LocalDataSource는 만들지 않는다.
struct ChatBotRemoteDataSource: Sendable {
    func streamEvents(message: String) -> AsyncThrowingStream<ChatProxyStreamEvent, Error> {
        @Dependency(\.sseClient) var sseClient
        let request = ChatProxyRequest(messages: [ChatProxyMessage(role: "user", content: message)])
        return ChatProxySSEParser.parse(frames: sseClient.stream(request))
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
