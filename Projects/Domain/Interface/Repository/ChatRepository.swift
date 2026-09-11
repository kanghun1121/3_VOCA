import Foundation

import Dependencies

/// 챗봇 메시지 전송 및 SSE 스트리밍 응답 수신을 추상화한 포트. 실제 구현은 Data 모듈에서 제공한다.
public struct ChatRepository: Sendable {
    public var streamMessage: @Sendable (_ message: String, _ wordID: String) -> AsyncThrowingStream<String, Error>
    /// 로컬 캐시를 먼저 emit하고, 서버 조회가 끝나면 그 결과를 이어서 emit한다(서브플랜 9) —
    /// 단발 반환값으로는 "지금은 이거, 잠시 후엔 저거"를 표현할 수 없어 스트림으로 되어 있다.
    public var fetchHistory: @Sendable (_ wordID: String) -> AsyncThrowingStream<ChatHistory, Error>
    /// 이 단어에 진행 중인 전송을 서버에 정지 요청한다(서브플랜 10) — 로컬에서 스트림을 강제로
    /// 끊지 않는다. 서버가 지금까지 생성한 내용을 마저 흘려보낸 뒤 스스로 스트림을 닫을 때까지,
    /// 호출부는 `streamMessage`가 반환한 스트림을 계속 소비한다. sse_id 같은 프로토콜 상관관계
    /// 식별자는 Data 레이어 안에서만 관리되고(`ChatSessionStore`) 이 포트 밖으로 노출되지
    /// 않는다 — 정지 프로토콜이 나중에 또 바뀌어도 이 시그니처(그리고 그걸 쓰는 ViewModel)는
    /// 그대로다. 진행 중인 전송이 없으면(이미 끝났거나 애초에 없었으면) 조용히 아무 일도 안 한다.
    public var stopStreaming: @Sendable (_ wordID: String) async throws -> Void

    public init(
        streamMessage: @escaping @Sendable (_ message: String, _ wordID: String) -> AsyncThrowingStream<String, Error>,
        fetchHistory: @escaping @Sendable (_ wordID: String) -> AsyncThrowingStream<ChatHistory, Error>,
        stopStreaming: @escaping @Sendable (_ wordID: String) async throws -> Void
    ) {
        self.streamMessage = streamMessage
        self.fetchHistory = fetchHistory
        self.stopStreaming = stopStreaming
    }
}

extension ChatRepository: TestDependencyKey {
    public static let testValue = ChatRepository(
        streamMessage: unimplemented("\(Self.self).streamMessage"),
        fetchHistory: unimplemented("\(Self.self).fetchHistory"),
        stopStreaming: unimplemented("\(Self.self).stopStreaming")
    )
}

public extension DependencyValues {
    var chatRepository: ChatRepository {
        get { self[ChatRepository.self] }
        set { self[ChatRepository.self] = newValue }
    }
}
