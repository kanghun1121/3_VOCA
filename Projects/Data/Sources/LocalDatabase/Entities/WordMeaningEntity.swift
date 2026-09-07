import SwiftData

@Model
final class WordMeaningEntity {
    @Attribute(.unique) var id: Int
    var wordID: Int
    var pos: String
    var ko: String
    /// 한 단어가 여러 뜻을 가질 때 "대표 뜻"(정렬 후 첫 번째)을 결정하는 필드라 반드시
    /// 유지하고, 조회 시 이 필드로 명시적으로 정렬해야 한다 — 정렬 없이 조회하면 대표 뜻이
    /// 실행마다 달라지는 회귀가 생긴다.
    var rank: Int

    init(id: Int, wordID: Int, pos: String, ko: String, rank: Int) {
        self.id = id
        self.wordID = wordID
        self.pos = pos
        self.ko = ko
        self.rank = rank
    }
}
