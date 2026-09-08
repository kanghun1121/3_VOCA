import SwiftData

@Model
final class LessonEntity {
    @Attribute(.unique) var id: Int
    var levelID: Int
    var lessonNumber: Int
    /// `LessonWordEntity`(조인 테이블)였던 것을 흡수한 필드. 유일한 소비 지점이
    /// `orderedWordIDs(lessonID:)`였고 그 메서드조차 엔티티가 아니라 position 정렬된
    /// `[Int]`만 반환했다 — 조인 테이블로 존재할 이유가 애초에 없었다. position 값 자체는
    /// 코드 어디에도 노출되지 않고 정렬 결과로만 쓰이므로, 배열 인덱스가 곧 그 정렬 결과다.
    var orderedWordIDs: [Int]

    init(id: Int, levelID: Int, lessonNumber: Int, orderedWordIDs: [Int] = []) {
        self.id = id
        self.levelID = levelID
        self.lessonNumber = lessonNumber
        self.orderedWordIDs = orderedWordIDs
    }
}
