import Foundation

import DomainInterface

import Dependencies

/// `LearningHistory`를 lessonID별로 캐싱하고 다수의 구독자에게 브로드캐스트하는 Store.
/// 신규 구독은 등록 즉시 해당 id의 현재 값을 replay 받고, 이후 `set`이 호출될 때마다
/// 그 id를 구독 중인 모든 구독자가 갱신을 받는다.
actor LearningHistoryStore {
    private var values: [String: LearningHistory] = [:]
    private var continuations: [String: [UUID: AsyncStream<LearningHistory>.Continuation]] = [:]

    func register(id: String, subscriberID: UUID, continuation: AsyncStream<LearningHistory>.Continuation) {
        continuations[id, default: [:]][subscriberID] = continuation
        if let value = values[id] {
            continuation.yield(value)
        }
    }

    func unregister(id: String, subscriberID: UUID) {
        continuations[id]?[subscriberID] = nil
    }

    func set(id: String, _ newValue: LearningHistory) {
        values[id] = newValue
        for continuation in continuations[id, default: [:]].values {
            continuation.yield(newValue)
        }
    }
}

extension LearningHistoryStore: DependencyKey {
    static let liveValue = LearningHistoryStore()
}

extension DependencyValues {
    var learningHistoryStore: LearningHistoryStore {
        get { self[LearningHistoryStore.self] }
        set { self[LearningHistoryStore.self] = newValue }
    }
}
