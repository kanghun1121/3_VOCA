import Foundation

import DomainInterface

import Dependencies

/// `LearningLibrary`의 최신 스냅샷을 들고 있다가 다수의 구독자에게 브로드캐스트하는 Store.
/// 신규 구독은 등록 즉시 현재 값을 replay 받고, 이후 `set`이 호출될 때마다 모든 구독자가 갱신을 받는다.
actor LearningLibraryStore {
    private var value: LearningLibrary?
    private var continuations: [UUID: AsyncStream<LearningLibrary>.Continuation] = [:]

    func register(id: UUID, continuation: AsyncStream<LearningLibrary>.Continuation) {
        continuations[id] = continuation
        if let value {
            continuation.yield(value)
        }
    }

    func unregister(id: UUID) {
        continuations[id] = nil
    }

    /// 테스트 전용 — 현재 등록된 구독자 수(정리가 제대로 이뤄지는지 확인용).
    var subscriberCount: Int { continuations.count }

    func set(_ newValue: LearningLibrary) {
        value = newValue
        for continuation in continuations.values {
            continuation.yield(newValue)
        }
    }
}

extension LearningLibraryStore: DependencyKey {
    static let liveValue = LearningLibraryStore()
}

extension DependencyValues {
    var learningLibraryStore: LearningLibraryStore {
        get { self[LearningLibraryStore.self] }
        set { self[LearningLibraryStore.self] = newValue }
    }
}
