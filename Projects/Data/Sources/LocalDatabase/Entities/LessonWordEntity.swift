import SwiftData

/// lesson_words 조인 테이블. position이라는 페이로드가 있어 순수 many-to-many
/// 관계로는 표현할 수 없어 조인 레코드를 그대로 모델링한다.
@Model
final class LessonWordEntity {
    var lessonID: Int
    var wordID: Int
    var position: Int

    init(lessonID: Int, wordID: Int, position: Int) {
        self.lessonID = lessonID
        self.wordID = wordID
        self.position = position
    }
}
