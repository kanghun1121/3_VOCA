import Foundation

import DomainInterface

import Dependencies

/// 전체 완료 기록(`[LessonCompletionRecord]`)의 최신 스냅샷을 들고 있다가 다수의 구독자에게
/// 브로드캐스트하는 Store. `VocabularyLibraryStore`와 동일한 모양이다 — 신규 구독은 등록 즉시
/// 현재 값이 있을 때만 replay 받고, 이후 `set`이 호출될 때마다 모든 구독자가 갱신을 받는다.
actor LearningHistoryFeedStore {
    private var value: [LessonCompletionRecord]?
    private var continuations: [UUID: AsyncStream<[LessonCompletionRecord]>.Continuation] = [:]

    func register(id: UUID, continuation: AsyncStream<[LessonCompletionRecord]>.Continuation) {
        continuations[id] = continuation
        if let value {
            continuation.yield(value)
        }
    }

    func unregister(id: UUID) {
        continuations[id] = nil
    }

    func set(_ newValue: [LessonCompletionRecord]) {
        value = newValue
        for continuation in continuations.values {
            continuation.yield(newValue)
        }
    }
}

extension LearningHistoryFeedStore: DependencyKey {
    static let liveValue = LearningHistoryFeedStore()
}

extension DependencyValues {
    var learningHistoryFeedStore: LearningHistoryFeedStore {
        get { self[LearningHistoryFeedStore.self] }
        set { self[LearningHistoryFeedStore.self] = newValue }
    }
}
