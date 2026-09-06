import XCTest

import DomainInterface
import NetworkingInterface

import Dependencies

@testable import Data

/// `AudioRepository.liveValue`의 memory → disk → network 3계층 오케스트레이션을 검증한다.
/// `AudioMemoryCache`/`AudioDiskCache`는 실제 타입을 그대로 테스트 더블로 쓴다(상태가
/// 단순해 별도 프로토콜/스파이가 필요 없다) — `httpClient`만 스텁으로 대체한다.
final class AudioRepositoryTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = URL.temporaryDirectory.appending(path: "AudioRepositoryTests-\(UUID().uuidString)")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    // MARK: - url(term:)

    func test_url_메모리에_있으면_그대로_반환하고_디스크는_건드리지_않는다() async {
        let memory = AudioMemoryCache()
        let cachedURL = URL(string: "file:///cached.mp3")!
        await memory.markReady("apple", url: cachedURL)

        let result = await withDependencies {
            $0.audioMemoryCache = memory
            $0.audioDiskCache = AudioDiskCache(directory: directory)
        } operation: {
            await AudioRepository.liveValue.url("apple")
        }

        XCTAssertEqual(result, cachedURL)
    }

    func test_url_메모리엔_없지만_디스크에_있으면_디스크_URL을_반환하고_메모리에_기록한다() async throws {
        let memory = AudioMemoryCache()
        let disk = AudioDiskCache(directory: directory)
        let diskURL = try disk.store(Data("apple-mp3".utf8), for: "apple")

        let result = await withDependencies {
            $0.audioMemoryCache = memory
            $0.audioDiskCache = disk
        } operation: {
            await AudioRepository.liveValue.url("apple")
        }

        XCTAssertEqual(result, diskURL)
        let memoized = await memory.url(for: "apple")
        XCTAssertEqual(memoized, diskURL)
    }

    func test_url_메모리와_디스크_모두_없으면_nil을_반환한다() async {
        let result = await withDependencies {
            $0.audioMemoryCache = AudioMemoryCache()
            $0.audioDiskCache = AudioDiskCache(directory: directory)
        } operation: {
            await AudioRepository.liveValue.url("ghost")
        }

        XCTAssertNil(result)
    }

    // MARK: - fetchURL(term:audioUrl:)

    func test_fetchURL_메모리_hit이면_네트워크를_타지_않고_그대로_반환한다() async {
        let memory = AudioMemoryCache()
        let cachedURL = URL(string: "file:///cached.mp3")!
        await memory.markReady("apple", url: cachedURL)

        let result = await withDependencies {
            $0.audioMemoryCache = memory
            $0.audioDiskCache = AudioDiskCache(directory: directory)
            $0.httpClient = StubHTTPClient { _ in
                XCTFail("메모리 hit이면 네트워크를 호출하면 안 된다")
                throw NetworkError.invalidRequest
            }
        } operation: {
            await AudioRepository.liveValue.fetchURL("apple", "https://example.com/apple.mp3")
        }

        XCTAssertEqual(result, cachedURL)
    }

    func test_fetchURL_디스크_hit이면_네트워크를_타지_않고_메모리에_기록한다() async throws {
        let memory = AudioMemoryCache()
        let disk = AudioDiskCache(directory: directory)
        let diskURL = try disk.store(Data("apple-mp3".utf8), for: "apple")

        let result = await withDependencies {
            $0.audioMemoryCache = memory
            $0.audioDiskCache = disk
            $0.httpClient = StubHTTPClient { _ in
                XCTFail("디스크 hit이면 네트워크를 호출하면 안 된다")
                throw NetworkError.invalidRequest
            }
        } operation: {
            await AudioRepository.liveValue.fetchURL("apple", "https://example.com/apple.mp3")
        }

        XCTAssertEqual(result, diskURL)
        let memoized = await memory.url(for: "apple")
        XCTAssertEqual(memoized, diskURL)
    }

    func test_fetchURL_캐시_미스면_네트워크에서_다운로드해_디스크에_저장하고_메모리에_기록한다() async throws {
        let memory = AudioMemoryCache()
        let disk = AudioDiskCache(directory: directory)
        let mp3Data = Data("network-bytes".utf8)

        let result = await withDependencies {
            $0.audioMemoryCache = memory
            $0.audioDiskCache = disk
            $0.httpClient = StubHTTPClient { _ in mp3Data }
        } operation: {
            await AudioRepository.liveValue.fetchURL("apple", "https://example.com/apple.mp3")
        }

        let fileURL = try XCTUnwrap(result)
        XCTAssertEqual(try Data(contentsOf: fileURL), mp3Data)
        XCTAssertEqual(disk.url(for: "apple"), fileURL)
        let memoized = await memory.url(for: "apple")
        XCTAssertEqual(memoized, fileURL)
    }

    func test_fetchURL_네트워크_다운로드가_실패하면_nil을_반환하고_아무것도_저장하지_않는다() async {
        let memory = AudioMemoryCache()
        let disk = AudioDiskCache(directory: directory)

        let result = await withDependencies {
            $0.audioMemoryCache = memory
            $0.audioDiskCache = disk
            $0.httpClient = StubHTTPClient { _ in throw NetworkError.invalidResponse }
        } operation: {
            await AudioRepository.liveValue.fetchURL("apple", "https://example.com/apple.mp3")
        }

        XCTAssertNil(result)
        XCTAssertNil(disk.url(for: "apple"))
        let memoized = await memory.url(for: "apple")
        XCTAssertNil(memoized)
    }

    func test_fetchURL_audioUrl이_잘못된_URL이면_네트워크_호출_없이_nil을_반환한다() async {
        let result = await withDependencies {
            $0.audioMemoryCache = AudioMemoryCache()
            $0.audioDiskCache = AudioDiskCache(directory: directory)
            $0.httpClient = StubHTTPClient { _ in
                XCTFail("잘못된 URL이면 네트워크를 시도하면 안 된다")
                throw NetworkError.invalidRequest
            }
        } operation: {
            await AudioRepository.liveValue.fetchURL("apple", "")
        }

        XCTAssertNil(result)
    }

    // MARK: - prefetch(words:)

    func test_prefetch_여러_단어를_각자의_계층에서_처리해_전부_메모리에_준비한다() async throws {
        let memory = AudioMemoryCache()
        let disk = AudioDiskCache(directory: directory)
        let cachedURL = URL(string: "file:///cached.mp3")!
        await memory.markReady("apple", url: cachedURL)
        let diskURL = try disk.store(Data("banana-mp3".utf8), for: "banana")
        let networkData = Data("cherry-mp3".utf8)

        await withDependencies {
            $0.audioMemoryCache = memory
            $0.audioDiskCache = disk
            $0.httpClient = StubHTTPClient { _ in networkData }
        } operation: {
            await AudioRepository.liveValue.prefetch([
                (term: "apple", audioUrl: "https://example.com/apple.mp3"),
                (term: "banana", audioUrl: "https://example.com/banana.mp3"),
                (term: "cherry", audioUrl: "https://example.com/cherry.mp3")
            ])
        }

        let appleMemoized = await memory.url(for: "apple")
        let bananaMemoized = await memory.url(for: "banana")
        let cherryMemoized = await memory.url(for: "cherry")

        XCTAssertEqual(appleMemoized, cachedURL)
        XCTAssertEqual(bananaMemoized, diskURL)
        let cherryURL = try XCTUnwrap(cherryMemoized)
        XCTAssertEqual(try Data(contentsOf: cherryURL), networkData)
    }

    func test_prefetch_한_단어가_네트워크_실패해도_나머지_단어는_정상적으로_완료된다() async {
        let memory = AudioMemoryCache()
        let disk = AudioDiskCache(directory: directory)
        let goodData = Data("good-mp3".utf8)

        await withDependencies {
            $0.audioMemoryCache = memory
            $0.audioDiskCache = disk
            $0.httpClient = StubHTTPClient { url in
                if url.absoluteString.contains("fail") {
                    throw NetworkError.invalidResponse
                }
                return goodData
            }
        } operation: {
            await AudioRepository.liveValue.prefetch([
                (term: "good", audioUrl: "https://example.com/good.mp3"),
                (term: "bad", audioUrl: "https://example.com/fail.mp3")
            ])
        }

        let goodMemoized = await memory.url(for: "good")
        let badMemoized = await memory.url(for: "bad")

        XCTAssertNotNil(goodMemoized)
        XCTAssertNil(badMemoized)
        XCTAssertNil(disk.url(for: "bad"))
    }
}

/// 테스트 전용 — `data(from:)`만 스텁으로 대체하고 나머지 메서드는 쓰이지 않으므로 실패로 던진다.
private struct StubHTTPClient: HTTPClienting {
    var dataHandler: @Sendable (URL) async throws -> Data

    init(_ dataHandler: @escaping @Sendable (URL) async throws -> Data) {
        self.dataHandler = dataHandler
    }

    func request<T: Decodable>(_ requestable: any Requestable) async throws -> T {
        throw NetworkError.invalidRequest
    }

    func request(_ requestable: any Requestable) async throws {
        throw NetworkError.invalidRequest
    }

    func data(from url: URL) async throws -> Data {
        try await dataHandler(url)
    }
}
