import SwiftData

/// #106 리팩토링 이전 스키마(7개 엔티티)를 그대로 동결한 스냅샷.
/// `WordEntity`/`LessonEntity`/`WordMeaningEntity`/`LessonWordEntity`는 이후 리팩토링으로
/// 형태가 바뀌거나 삭제되므로 이 안에 과거 형태를 그대로 복제해 둔다 — 그래야
/// `LocalDatabaseMigrationPlan`이 "V1 → V2" 전환을 정의할 수 있다. `LevelEntity`/
/// `WordExampleEntity`/`LearningHistoryEntity`는 리팩토링으로 변경되지 않으므로 최신
/// 정의를 그대로 참조한다(중복 선언하지 않음).
enum LocalDatabaseSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            LevelEntity.self,
            LessonEntity.self,
            LessonWordEntity.self,
            WordEntity.self,
            WordMeaningEntity.self,
            WordExampleEntity.self,
            LearningHistoryEntity.self,
        ]
    }

    @Model
    final class WordEntity {
        @Attribute(.unique) var id: Int
        var word: String
        var levelID: Int
        var pronunciation: String
        var audioUrl: String
        var distractors: [String]

        init(
            id: Int,
            word: String,
            levelID: Int,
            pronunciation: String,
            audioUrl: String,
            distractors: [String]
        ) {
            self.id = id
            self.word = word
            self.levelID = levelID
            self.pronunciation = pronunciation
            self.audioUrl = audioUrl
            self.distractors = distractors
        }
    }

    @Model
    final class LessonEntity {
        @Attribute(.unique) var id: Int
        var levelID: Int
        var lessonNumber: Int
        var wordCount: Int

        init(id: Int, levelID: Int, lessonNumber: Int, wordCount: Int) {
            self.id = id
            self.levelID = levelID
            self.lessonNumber = lessonNumber
            self.wordCount = wordCount
        }
    }

    @Model
    final class WordMeaningEntity {
        @Attribute(.unique) var id: Int
        var wordID: Int
        var pos: String
        var ko: String
        var rank: Int

        init(id: Int, wordID: Int, pos: String, ko: String, rank: Int) {
            self.id = id
            self.wordID = wordID
            self.pos = pos
            self.ko = ko
            self.rank = rank
        }
    }

    /// lesson_words 조인 테이블. V2에서 `LessonEntity.orderedWordIDs`로 흡수되어 삭제된다.
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
}
