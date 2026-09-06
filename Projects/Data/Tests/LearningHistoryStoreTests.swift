import XCTest

import DomainInterface
@testable import Data

final class LearningHistoryStoreTests: XCTestCase {
    func test_캐시가_없으면_구독해도_아무것도_방출하지_않는다() async {
        let store = LearningHistoryStore()
        let (stream, continuation) = AsyncStream<LearningHistory>.makeStream()

        await store.register(id: "lesson_1", subscriberID: UUID(), continuation: continuation)
        continuation.finish()

        var received: [LearningHistory] = []
        for await value in stream { received.append(value) }

        XCTAssertTrue(received.isEmpty)
    }

    func test_set_이후_신규_구독은_현재_값을_즉시_replay_받는다() async {
        let store = LearningHistoryStore()
        let history = makeHistory(studyCount: 1)
        await store.set(id: "lesson_1", history)

        let (stream, continuation) = AsyncStream<LearningHistory>.makeStream()
        await store.register(id: "lesson_1", subscriberID: UUID(), continuation: continuation)
        continuation.finish()

        var received: [LearningHistory] = []
        for await value in stream { received.append(value) }

        XCTAssertEqual(received, [history])
    }

    func test_같은_id를_구독한_구독자_2명이_동일한_set을_모두_받는다() async {
        let store = LearningHistoryStore()
        let history = makeHistory(studyCount: 1)

        let (streamA, continuationA) = AsyncStream<LearningHistory>.makeStream()
        let (streamB, continuationB) = AsyncStream<LearningHistory>.makeStream()
        await store.register(id: "lesson_1", subscriberID: UUID(), continuation: continuationA)
        await store.register(id: "lesson_1", subscriberID: UUID(), continuation: continuationB)

        await store.set(id: "lesson_1", history)
        continuationA.finish()
        continuationB.finish()

        var receivedA: [LearningHistory] = []
        for await value in streamA { receivedA.append(value) }
        var receivedB: [LearningHistory] = []
        for await value in streamB { receivedB.append(value) }

        XCTAssertEqual(receivedA, [history])
        XCTAssertEqual(receivedB, [history])
    }

    func test_다른_id로_구독_중인_구독자는_다른_id의_set에_영향받지_않는다() async {
        let store = LearningHistoryStore()
        let historyLesson1 = makeHistory(studyCount: 1)

        let (streamLesson1, continuationLesson1) = AsyncStream<LearningHistory>.makeStream()
        let (streamLesson2, continuationLesson2) = AsyncStream<LearningHistory>.makeStream()
        await store.register(id: "lesson_1", subscriberID: UUID(), continuation: continuationLesson1)
        await store.register(id: "lesson_2", subscriberID: UUID(), continuation: continuationLesson2)

        await store.set(id: "lesson_1", historyLesson1)
        continuationLesson1.finish()
        continuationLesson2.finish()

        var receivedLesson1: [LearningHistory] = []
        for await value in streamLesson1 { receivedLesson1.append(value) }
        var receivedLesson2: [LearningHistory] = []
        for await value in streamLesson2 { receivedLesson2.append(value) }

        XCTAssertEqual(receivedLesson1, [historyLesson1])
        XCTAssertTrue(receivedLesson2.isEmpty)
    }

    func test_연속_set이_순서대로_전달된다() async {
        let store = LearningHistoryStore()
        let (stream, continuation) = AsyncStream<LearningHistory>.makeStream()
        await store.register(id: "lesson_1", subscriberID: UUID(), continuation: continuation)

        let first = makeHistory(studyCount: 1)
        let second = makeHistory(studyCount: 2)
        let third = makeHistory(studyCount: 3)
        await store.set(id: "lesson_1", first)
        await store.set(id: "lesson_1", second)
        await store.set(id: "lesson_1", third)
        continuation.finish()

        var received: [LearningHistory] = []
        for await value in stream { received.append(value) }

        XCTAssertEqual(received, [first, second, third])
    }

    func test_한_구독자가_종료돼도_나머지는_계속_수신한다() async {
        let store = LearningHistoryStore()
        let subscriberA = UUID()
        let subscriberB = UUID()
        let (streamA, continuationA) = AsyncStream<LearningHistory>.makeStream()
        let (streamB, continuationB) = AsyncStream<LearningHistory>.makeStream()
        await store.register(id: "lesson_1", subscriberID: subscriberA, continuation: continuationA)
        await store.register(id: "lesson_1", subscriberID: subscriberB, continuation: continuationB)

        // A는 종료(unregister)하고 B만 계속 구독한다.
        continuationA.finish()
        await store.unregister(id: "lesson_1", subscriberID: subscriberA)

        let history = makeHistory(studyCount: 1)
        await store.set(id: "lesson_1", history)
        continuationB.finish()

        var receivedA: [LearningHistory] = []
        for await value in streamA { receivedA.append(value) }
        var receivedB: [LearningHistory] = []
        for await value in streamB { receivedB.append(value) }

        XCTAssertTrue(receivedA.isEmpty)
        XCTAssertEqual(receivedB, [history])
    }
}

private func makeHistory(studyCount: Int) -> LearningHistory {
    LearningHistory(firstCompletedAt: "2026.05.01", studyCount: studyCount)
}
