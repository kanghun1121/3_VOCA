import Foundation

import DomainInterface

/// `Lesson`을 lessonID별로 캐싱하는 단순 Store. 콘텐츠는 completeLesson 등으로 바뀌지 않는 정적
/// 데이터이므로(학습 이력은 `LearningHistoryStore`가 별도로 다룸) 구독/브로드캐스트가 필요 없다.
actor LessonStore {
    private var values: [String: Lesson] = [:]

    func fetch(_ id: String) -> Lesson? {
        values[id]
    }

    func set(_ id: String, _ lesson: Lesson) {
        values[id] = lesson
    }
}
