import SwiftData

/// `WordMeaningEntity`였던 것을 흡수한 값 타입. `wordDetail`/`lessonWords` 두 접근 경로
/// 모두에서 항상 `WordEntity`와 동시에 조회돼(독립 조회 지점 0곳) 별도 @Model로 둘 이유가
/// 없었다 — `distractors`와 같은 이유로 배열 프로퍼티로 흡수한다. `rank`는 배열 인덱스와
/// 동형이지만, 정렬 보장을 "쓰기 시점(삽입 순서)"이 아니라 "읽기 시점(매핑 경계에서 명시적
/// 정렬)"에 두기 위해 필드로 유지한다 — 시더가 정렬을 빠뜨려도 조회 시 항상 rank 오름차순으로
/// 바로잡힌다.
///
/// 반대로 `WordExampleEntity`는 흡수하지 않는다: 예문은 `wordDetail`(단어 상세)에서만 필요하고
/// `lessonWords`(레슨/게임 화면, 배치 조회 핫패스)에서는 전혀 쓰이지 않는데다 페이로드가
/// 뜻보다 훨씬 커서(단어당 평균 2.4KB, 뜻 대비 34배), 흡수하면 핫패스가 매번 불필요한 예문
/// 데이터를 함께 읽게 된다. 판단 기준은 "부모와 함께 조회되는가"가 아니라 "모든 조회 경로에서
/// 함께 필요한가 × 페이로드 크기"다.
struct WordMeaningPayload: Codable {
    let id: Int
    let pos: String
    let ko: String
    let rank: Int
}

@Model
final class WordEntity {
    @Attribute(.unique) var id: Int
    var word: String
    var levelID: Int
    var pronunciation: String
    var audioUrl: String
    /// distractors.json은 단어당 정확히 1행(1:1)이라 별도 엔티티 대신 속성으로 흡수한다.
    var distractors: [String]
    var meanings: [WordMeaningPayload]

    init(
        id: Int,
        word: String,
        levelID: Int,
        pronunciation: String,
        audioUrl: String,
        distractors: [String],
        meanings: [WordMeaningPayload] = []
    ) {
        self.id = id
        self.word = word
        self.levelID = levelID
        self.pronunciation = pronunciation
        self.audioUrl = audioUrl
        self.distractors = distractors
        self.meanings = meanings
    }
}
