import Foundation

import Dependencies

/// 챗봇 메시지 전송 및 SSE 스트리밍 응답 수신을 추상화한 포트. 실제 구현은 Data 모듈에서 제공한다.
public struct ChatRepository: Sendable {
    public var streamMessage: @Sendable (_ message: String, _ wordID: String) -> AsyncThrowingStream<String, Error>
    /// 로컬 캐시를 먼저 emit하고, 서버 조회가 끝나면 그 결과를 이어서 emit한다(서브플랜 9) —
    /// 단발 반환값으로는 "지금은 이거, 잠시 후엔 저거"를 표현할 수 없어 스트림으로 되어 있다.
    public var fetchHistory: @Sendable (_ wordID: String) -> AsyncThrowingStream<ChatHistory, Error>

    public init(
        streamMessage: @escaping @Sendable (_ message: String, _ wordID: String) -> AsyncThrowingStream<String, Error>,
        fetchHistory: @escaping @Sendable (_ wordID: String) -> AsyncThrowingStream<ChatHistory, Error>
    ) {
        self.streamMessage = streamMessage
        self.fetchHistory = fetchHistory
    }
}

extension ChatRepository: TestDependencyKey {
    public static let testValue = ChatRepository(
        streamMessage: unimplemented("\(Self.self).streamMessage"),
        fetchHistory: unimplemented("\(Self.self).fetchHistory")
    )
}

public extension DependencyValues {
    var chatRepository: ChatRepository {
        get { self[ChatRepository.self] }
        set { self[ChatRepository.self] = newValue }
    }
}
