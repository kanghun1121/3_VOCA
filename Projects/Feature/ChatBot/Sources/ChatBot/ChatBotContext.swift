import Foundation

/// ChatBot 화면이 문법 분석 대상으로 받는 최소 데이터 계약.
///
/// 호출 화면(예: WordDetail)이 가진 도메인 모델 전체가 아니라, 헤더 카드를 그리는 데 실제로
/// 필요한 값만 좁혀서 받는다 — ChatBot이 `WordDetail`의 정의/발음/전체 예문 배열까지 알 이유가
/// 없기 때문이다.
public struct ChatBotContext: Equatable, Sendable {
    /// 하이라이트할 대상 단어(예: "address").
    public let term: String
    /// 대상 단어가 포함된 예문 문장.
    public let sentence: String
    /// ChatBotContextCard 칩에 표시할 완성된 레벨 라벨(예: "초급").
    public let levelLabel: String

    public init(
        term: String,
        sentence: String,
        levelLabel: String
    ) {
        self.term = term
        self.sentence = sentence
        self.levelLabel = levelLabel
    }
}
