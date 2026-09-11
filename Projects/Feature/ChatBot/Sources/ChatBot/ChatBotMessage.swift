import Foundation

/// 대화 히스토리 한 줄. 사용자 질문과 AI 응답이 순서대로 쌓인다.
struct ChatBotMessage: Identifiable, Equatable {
    enum Role: Equatable {
        case user
        case assistant
    }

    let id = UUID()
    let role: Role
    var text: String
    /// AI 응답 자리표시 상태 — 첫 청크가 도착하기 전까지 true. 이 동안은 텍스트 대신
    /// 스피너 + 대기 문구를 렌더한다.
    var isGenerating: Bool = false
    /// 스트리밍 실패로 대체된 "답변을 가져오지 못했어요" 메시지 — 아이콘 + 문구로
    /// 렌더된다. `isGenerating`이 true인 채로 실패하면 그 자리에서 false로 내리고
    /// 이 플래그를 켜므로, 두 플래그가 동시에 true인 경우는 없다. 다음 전송 시작 시
    /// 히스토리에서 제거된다(계속 남는 정상 응답과 다름).
    var isError: Bool = false
    /// 히스토리 로드로 채워진 메시지인지 — 방금 보낸 메시지와 구분해, 뷰가 "전송 중
    /// 응답 자리 예약"(뷰포트 높이만큼의 minHeight) 같은 라이브 전송 전용 연출을
    /// 히스토리 메시지에는 적용하지 않도록 한다.
    var isFromHistory: Bool = false
}
