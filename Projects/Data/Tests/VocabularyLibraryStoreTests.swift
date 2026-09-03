import XCTest

import DomainInterface
@testable import Data

final class VocabularyLibraryStoreTests: XCTestCase {
    func test_캐시가_없으면_구독해도_아무것도_방출하지_않는다() async {
        let store = VocabularyLibraryStore()
        let (stream, continuation) = AsyncStream<VocabularyLibrary>.makeStream()

        await store.register(id: UUID(), continuation: continuation)
        continuation.finish()

        var received: [VocabularyLibrary] = []
        for await library in stream { received.append(library) }

        XCTAssertTrue(received.isEmpty)
    }

    func test_set_이후_신규_구독은_현재_값을_즉시_replay_받는다() async {
        let store = VocabularyLibraryStore()
        let library = makeLibrary(levelID: "level_1")
        await store.set(library)

        let (stream, continuation) = AsyncStream<VocabularyLibrary>.makeStream()
        await store.register(id: UUID(), continuation: continuation)
        continuation.finish()

        var received: [VocabularyLibrary] = []
        for await value in stream { received.append(value) }

        XCTAssertEqual(received, [library])
    }

    func test_구독자_2명이_동일한_set을_모두_받는다() async {
        let store = VocabularyLibraryStore()
        let library = makeLibrary(levelID: "level_1")

        let (streamA, continuationA) = AsyncStream<VocabularyLibrary>.makeStream()
        let (streamB, continuationB) = AsyncStream<VocabularyLibrary>.makeStream()
        await store.register(id: UUID(), continuation: continuationA)
        await store.register(id: UUID(), continuation: continuationB)

        await store.set(library)
        continuationA.finish()
        continuationB.finish()

        var receivedA: [VocabularyLibrary] = []
        for await value in streamA { receivedA.append(value) }
        var receivedB: [VocabularyLibrary] = []
        for await value in streamB { receivedB.append(value) }

        XCTAssertEqual(receivedA, [library])
        XCTAssertEqual(receivedB, [library])
    }

    func test_한_구독자가_종료돼도_나머지는_계속_수신하고_continuation은_정리된다() async {
        let store = VocabularyLibraryStore()
        let idA = UUID()
        let idB = UUID()
        let (streamA, continuationA) = AsyncStream<VocabularyLibrary>.makeStream()
        let (streamB, continuationB) = AsyncStream<VocabularyLibrary>.makeStream()
        await store.register(id: idA, continuation: continuationA)
        await store.register(id: idB, continuation: continuationB)
        let countAfterBothRegister = await store.subscriberCount
        XCTAssertEqual(countAfterBothRegister, 2)

        // A는 종료(unregister)하고 B만 계속 구독한다.
        continuationA.finish()
        await store.unregister(id: idA)
        let countAfterUnregisterA = await store.subscriberCount
        XCTAssertEqual(countAfterUnregisterA, 1)

        let library = makeLibrary(levelID: "level_1")
        await store.set(library)
        continuationB.finish()

        var receivedA: [VocabularyLibrary] = []
        for await value in streamA { receivedA.append(value) }
        var receivedB: [VocabularyLibrary] = []
        for await value in streamB { receivedB.append(value) }

        XCTAssertTrue(receivedA.isEmpty)
        XCTAssertEqual(receivedB, [library])
    }

    func test_연속_set이_순서대로_전달된다() async {
        let store = VocabularyLibraryStore()
        let (stream, continuation) = AsyncStream<VocabularyLibrary>.makeStream()
        await store.register(id: UUID(), continuation: continuation)

        let first = makeLibrary(levelID: "level_1")
        let second = makeLibrary(levelID: "level_2")
        let third = makeLibrary(levelID: "level_3")
        await store.set(first)
        await store.set(second)
        await store.set(third)
        continuation.finish()

        var received: [VocabularyLibrary] = []
        for await value in stream { received.append(value) }

        XCTAssertEqual(received, [first, second, third])
    }
}

private func makeLibrary(levelID: String) -> VocabularyLibrary {
    VocabularyLibrary(levels: [
        LevelSummary(
            id: levelID,
            level: 1,
            name: "Level 1",
            difficulty: "A1",
            totalSessions: 1,
            completedSessions: 0,
            sessions: []
        ),
    ])
}
