import XCTest

@testable import Data

final class AudioMemoryCacheTests: XCTestCase {
    // MARK: - entry 개수 상한 (LRU 삭제)

    func test_상한_이하일_때는_entry를_제거하지_않는다() async {
        let sut = AudioMemoryCache(countLimit: 3)
        await sut.markReady("apple", url: URL(string: "file:///apple.mp3")!)
        await sut.markReady("banana", url: URL(string: "file:///banana.mp3")!)

        let apple = await sut.url(for: "apple")
        let banana = await sut.url(for: "banana")

        XCTAssertNotNil(apple)
        XCTAssertNotNil(banana)
    }

    func test_상한을_초과하면_가장_오래_접근되지_않은_term부터_제거한다() async {
        let sut = AudioMemoryCache(countLimit: 2)
        await sut.markReady("apple", url: URL(string: "file:///apple.mp3")!)
        await sut.markReady("banana", url: URL(string: "file:///banana.mp3")!)
        await sut.markReady("cherry", url: URL(string: "file:///cherry.mp3")!)

        let apple = await sut.url(for: "apple")
        let banana = await sut.url(for: "banana")
        let cherry = await sut.url(for: "cherry")

        XCTAssertNil(apple, "가장 오래된 term(apple)이 제거돼야 한다")
        XCTAssertNotNil(banana)
        XCTAssertNotNil(cherry)
    }

    func test_제거된_term을_재조회하면_nil을_반환한다() async {
        let sut = AudioMemoryCache(countLimit: 1)
        await sut.markReady("apple", url: URL(string: "file:///apple.mp3")!)
        await sut.markReady("banana", url: URL(string: "file:///banana.mp3")!)

        let apple = await sut.url(for: "apple")

        XCTAssertNil(apple)
    }

    func test_최근에_접근한_term은_상한_초과_시_삭제_대상에서_제외된다() async {
        let sut = AudioMemoryCache(countLimit: 2)
        await sut.markReady("apple", url: URL(string: "file:///apple.mp3")!)
        await sut.markReady("banana", url: URL(string: "file:///banana.mp3")!)
        _ = await sut.url(for: "apple") // apple을 재접근해 recency 갱신 → banana가 가장 오래됨
        await sut.markReady("cherry", url: URL(string: "file:///cherry.mp3")!)

        let apple = await sut.url(for: "apple")
        let banana = await sut.url(for: "banana")

        XCTAssertNotNil(apple, "최근에 접근한 term은 보호돼야 한다")
        XCTAssertNil(banana, "가장 오래 접근되지 않은 term이 제거돼야 한다")
    }

    // MARK: - staleness

    func test_동일_remoteURLString으로_조회하면_히트다() async {
        let sut = AudioMemoryCache()
        let url = URL(string: "file:///apple.mp3")!
        await sut.markReady("apple", url: url, remoteURLString: "https://example.com/apple.mp3")

        let result = await sut.url(for: "apple", expecting: "https://example.com/apple.mp3")

        XCTAssertEqual(result, url)
    }

    func test_remoteURLString이_다르면_stale로_취급해_nil을_반환한다() async {
        let sut = AudioMemoryCache()
        let url = URL(string: "file:///apple.mp3")!
        await sut.markReady("apple", url: url, remoteURLString: "https://example.com/apple.mp3")

        let result = await sut.url(for: "apple", expecting: "https://example.com/new-apple.mp3")

        XCTAssertNil(result)
    }

    func test_remoteURLString_없이_기록한_entry는_expecting_조회에서_항상_미스다() async {
        let sut = AudioMemoryCache()
        await sut.markReady("apple", url: URL(string: "file:///apple.mp3")!)

        let result = await sut.url(for: "apple", expecting: "https://example.com/apple.mp3")

        XCTAssertNil(result)
    }

    func test_stale_조회는_recency를_갱신하지_않는다() async {
        let sut = AudioMemoryCache(countLimit: 2)
        await sut.markReady("apple", url: URL(string: "file:///apple.mp3")!, remoteURLString: "https://example.com/apple.mp3")
        await sut.markReady("banana", url: URL(string: "file:///banana.mp3")!, remoteURLString: "https://example.com/banana.mp3")
        _ = await sut.url(for: "apple", expecting: "https://example.com/different.mp3") // stale, miss
        await sut.markReady("cherry", url: URL(string: "file:///cherry.mp3")!, remoteURLString: "https://example.com/cherry.mp3")

        let apple = await sut.url(for: "apple")

        XCTAssertNil(apple, "stale 조회는 recency를 보호하면 안 된다")
    }
}
