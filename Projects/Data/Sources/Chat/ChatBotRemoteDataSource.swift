import Foundation

import NetworkingInterface

import Dependencies

/// Supabase Edge Function 챗봇 프록시에 대한 원격 통신을 담당하는 계층 — 메시지 전송(SSE 스트림)과
/// 대화 히스토리 조회(GET)를 함께 묶는다. 프록시가 Claude Messages API 이벤트를 가공 없이 그대로
/// 전달하므로 스트림 이벤트 스키마 해석은 여전히 Claude 스키마 기준이다. 이 구조체 자체는 순수
/// 원격 호출만 담당하고 로컬 저장은 모른다 — 로컬 캐싱(`ChatHistoryLocalDataSource`)은
/// `ChatRepository+Live`가 이 데이터소스와 조합해서 처리한다(서브플랜 9).
struct ChatBotRemoteDataSource: Sendable {
    /// `wordID`/`conversationID`는 상호 배타적이다 — `conversationID`가 있으면(같은 화면 방문의
    /// 두 번째 이후 전송) `wordID`는 무시하고 안 보낸다. 응답 헤더 `x-conversation-id`는 SSE
    /// 바디가 아니라 첫 응답 시점에만 오므로(`SSEClienting.stream`의 `onResponse` 콜백), 그
    /// 값을 스트림 바디와 분리된 사이드 채널로 상위(`onConversationID`)에 전달한다.
    func streamEvents(
        message: String,
        wordID: String,
        sseID: String,
        conversationID: String?,
        onConversationID: @escaping @Sendable (String) -> Void
    ) async -> AsyncThrowingStream<ChatProxyStreamEvent, Error> {
        @Dependency(\.sseClient) var sseClient
        @Dependency(\.tokenProvider) var tokenProvider
        let accessToken = await tokenProvider.getAccessToken()
        let request = ChatProxyRequest(
            messages: [ChatProxyMessage(role: "user", content: message)],
            sseID: sseID,
            wordID: conversationID == nil ? wordID : nil,
            conversationID: conversationID,
            accessToken: accessToken
        )
        let frames = sseClient.stream(request) { response in
            if let newConversationID = response.value(forHTTPHeaderField: "x-conversation-id") {
                onConversationID(newConversationID)
            }
        }
        return ChatProxySSEParser.parse(frames: frames)
    }

    func fetchHistory(wordID: String) async throws -> ChatHistoryResponseDTO {
        // \.httpClient의 liveValue는 NoopInterceptor라 인증 헤더가 전혀 안 붙는다(HTTPClienting+Live.swift).
        // TokenRefreshInterceptor(Authorization 헤더 자동 부착 + 401 시 리프레시)를 타려면
        // authenticatedHTTPClient를 써야 한다 — AuthRemoteDataSource.exchangeAppleToken과 동일 패턴.
        @Dependency(\.authenticatedHTTPClient) var httpClient
        return try await httpClient.request(ChatHistoryRequest(wordID: wordID))
    }

    /// 진행 중인 전송을 서버에 "정지"시킨다 — 로컬에서 스트림 Task를 취소하는 게 아니라, 서버가
    /// 지금까지 생성한 내용을 마저 SSE로 흘려보낸 뒤 스스로 스트림을 닫도록 요청하는 것이다
    /// (서브플랜 10). idempotent라 실패해도 크게 문제되지 않는다 — 호출부(ChatRepository+Live)가
    /// best-effort로 처리한다.
    func stop(sseID: String) async throws {
        @Dependency(\.authenticatedHTTPClient) var httpClient
        try await httpClient.request(ChatStopRequest(sseID: sseID))
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
