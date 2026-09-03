import Foundation

import DomainInterface

/// `VocabularyLibrary`의 최신 스냅샷을 들고 있다가 다수의 구독자에게 브로드캐스트하는 Store.
/// 신규 구독은 등록 즉시 현재 값을 replay 받고, 이후 `set`이 호출될 때마다 모든 구독자가 갱신을 받는다.
actor VocabularyLibraryStore {
    private var value: VocabularyLibrary?
    private var continuations: [UUID: AsyncStream<VocabularyLibrary>.Continuation] = [:]

    func register(id: UUID, continuation: AsyncStream<VocabularyLibrary>.Continuation) {
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

    func set(_ newValue: VocabularyLibrary) {
        value = newValue
        for continuation in continuations.values {
            continuation.yield(newValue)
        }
    }
}
