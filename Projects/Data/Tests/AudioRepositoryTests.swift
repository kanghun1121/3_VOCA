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
        await memory.markReady("apple", url: cachedURL, remoteURLString: "https://example.com/apple.mp3")

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
        let diskURL = try disk.store(Data("apple-mp3".utf8), for: "apple", remoteURLString: "https://example.com/apple.mp3")

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

    // MARK: - staleness

    func test_fetchURL_디스크에_있어도_audioUrl이_바뀌면_stale로_취급해_재다운로드한다() async throws {
        let memory = AudioMemoryCache()
        let disk = AudioDiskCache(directory: directory)
        _ = try disk.store(Data("old-mp3".utf8), for: "apple", remoteURLString: "https://example.com/old-apple.mp3")
        let newData = Data("new-mp3".utf8)

        let result = await withDependencies {
            $0.audioMemoryCache = memory
            $0.audioDiskCache = disk
            $0.httpClient = StubHTTPClient { _ in newData }
        } operation: {
            await AudioRepository.liveValue.fetchURL("apple", "https://example.com/new-apple.mp3")
        }

        let fileURL = try XCTUnwrap(result)
        XCTAssertEqual(try Data(contentsOf: fileURL), newData)
    }

    func test_fetchURL_메모리가_이전_URL을_기억해도_다른_URL이_들어오면_원격에서_다시_받는다() async throws {
        let memory = AudioMemoryCache()
        let oldURL = URL(string: "file:///old-cached.mp3")!
        await memory.markReady("apple", url: oldURL, remoteURLString: "https://example.com/old-apple.mp3")
        let newData = Data("new-mp3".utf8)

        let result = await withDependencies {
            $0.audioMemoryCache = memory
            $0.audioDiskCache = AudioDiskCache(directory: directory)
            $0.httpClient = StubHTTPClient { _ in newData }
        } operation: {
            await AudioRepository.liveValue.fetchURL("apple", "https://example.com/new-apple.mp3")
        }

        let fileURL = try XCTUnwrap(result)
        XCTAssertNotEqual(fileURL, oldURL)
        XCTAssertEqual(try Data(contentsOf: fileURL), newData)
    }

    // MARK: - concurrency

    func test_prefetch_동시_다운로드에서_서로_다른_term의_파일이_섞이지_않는다() async throws {
        let memory = AudioMemoryCache()
        let disk = AudioDiskCache(directory: directory)
        let words = (0 ..< 20).map { (term: "word\($0)", audioUrl: "https://example.com/word\($0).mp3") }

        await withDependencies {
            $0.audioMemoryCache = memory
            $0.audioDiskCache = disk
            $0.httpClient = StubHTTPClient { url in Data(url.absoluteString.utf8) }
        } operation: {
            await AudioRepository.liveValue.prefetch(words)
        }

        for (term, audioUrl) in words {
            let cachedURL = await memory.url(for: term)
            let fileURL = try XCTUnwrap(cachedURL, "\(term)이 캐시되어 있어야 한다")
            let content = try Data(contentsOf: fileURL)
            XCTAssertEqual(content, Data(audioUrl.utf8), "\(term)의 내용이 다른 term과 섞였다")
        }
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
        await memory.markReady("apple", url: cachedURL, remoteURLString: "https://example.com/apple.mp3")
        let diskURL = try disk.store(Data("banana-mp3".utf8), for: "banana", remoteURLString: "https://example.com/banana.mp3")
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

    // MARK: - 3계층 캐시 통합 (memory → disk → network)

    /// memory/disk 인스턴스는 생성자 파라미터(`directory`, `countLimit` 등)로, repository는
    /// `withDependencies`로 주입해 3계층이 순서대로 폴백하고 각 계층이 다음 요청을 위해
    /// 갱신되는지를 한 흐름으로 검증한다.
    func test_3계층_캐시가_memory_disk_network_순서로_폴백하며_각_계층이_다음_요청을_위해_갱신된다() async throws {
        let memory = AudioMemoryCache(countLimit: 10)
        let disk = AudioDiskCache(directory: directory, sizeLimitBytes: 1_000_000)
        let networkData = Data("apple-from-network".utf8)

        // 1단계: memory/disk 모두 미스 → network에서 받아와 disk에 저장하고 memory에 기록한다.
        let firstResult = await withDependencies {
            $0.audioMemoryCache = memory
            $0.audioDiskCache = disk
            $0.httpClient = StubHTTPClient { _ in networkData }
        } operation: {
            await AudioRepository.liveValue.fetchURL("apple", "https://example.com/apple.mp3")
        }
        let firstURL = try XCTUnwrap(firstResult)
        XCTAssertEqual(try Data(contentsOf: firstURL), networkData, "1단계는 network에서 받은 데이터여야 한다")
        XCTAssertNotNil(disk.url(for: "apple", expecting: "https://example.com/apple.mp3"), "1단계 이후 disk에 저장되어 있어야 한다")

        // 2단계: memory가 비워져도(예: 세션 재시작 시뮬레이션) disk가 있으면 network를 타지 않는다.
        let freshMemory = AudioMemoryCache(countLimit: 10)
        let secondResult = await withDependencies {
            $0.audioMemoryCache = freshMemory
            $0.audioDiskCache = disk
            $0.httpClient = StubHTTPClient { _ in
                XCTFail("disk hit이면 network를 타면 안 된다")
                throw NetworkError.invalidRequest
            }
        } operation: {
            await AudioRepository.liveValue.fetchURL("apple", "https://example.com/apple.mp3")
        }
        XCTAssertEqual(secondResult, firstURL, "2단계는 disk에서 찾은 동일 파일이어야 한다")
        let memoizedAfterSecond = await freshMemory.url(for: "apple")
        XCTAssertEqual(memoizedAfterSecond, firstURL, "disk hit 이후 memory에도 다시 기록되어야 한다")

        // 3단계: memory에 다시 준비됐으니 disk/network 모두 타지 않는다(존재하지 않는 disk 경로를
        // 줘서 disk가 조회되면 즉시 미스가 나게 하고, network 스텁은 호출 시 실패하게 해 둘 중
        // 하나라도 타면 테스트가 실패하게 만든다).
        let unusedDiskDirectory = URL.temporaryDirectory.appending(path: "unused-\(UUID().uuidString)")
        let thirdResult = await withDependencies {
            $0.audioMemoryCache = freshMemory
            $0.audioDiskCache = AudioDiskCache(directory: unusedDiskDirectory)
            $0.httpClient = StubHTTPClient { _ in
                XCTFail("memory hit이면 network를 타면 안 된다")
                throw NetworkError.invalidRequest
            }
        } operation: {
            await AudioRepository.liveValue.fetchURL("apple", "https://example.com/apple.mp3")
        }
        XCTAssertEqual(thirdResult, firstURL, "3단계는 memory에서 바로 반환된 동일 파일이어야 한다")
    }

    /// disk `sizeLimitBytes`를 생성자로 작게 주입해도, `AudioDiskCache`를 직접 건드리지 않고
    /// `AudioRepository.prefetch`만 반복 호출하는 것만으로 LRU 삭제가 실제로 발동하는지 검증한다.
    func test_repository를_통한_prefetch만으로도_disk_용량_상한을_넘으면_LRU가_발동한다() async throws {
        let memory = AudioMemoryCache()
        let disk = AudioDiskCache(directory: directory, sizeLimitBytes: 250)
        let payload = Data(repeating: 0, count: 100)

        await withDependencies {
            $0.audioMemoryCache = memory
            $0.audioDiskCache = disk
            $0.httpClient = StubHTTPClient { _ in payload }
        } operation: {
            // 순차적으로 하나씩 prefetch해 mtime 순서를 보장한다(동시 다운로드 시 순서 보장 불가).
            await AudioRepository.liveValue.prefetch([(term: "old", audioUrl: "https://example.com/old.mp3")])
            await AudioRepository.liveValue.prefetch([(term: "new", audioUrl: "https://example.com/new.mp3")])
            await AudioRepository.liveValue.prefetch([(term: "newest", audioUrl: "https://example.com/newest.mp3")])
        }

        XCTAssertNil(disk.url(for: "old"), "repository만 거쳤어도 가장 오래된 항목은 LRU로 삭제돼야 한다")
        XCTAssertNotNil(disk.url(for: "new"))
        XCTAssertNotNil(disk.url(for: "newest"))
    }

    /// memory `countLimit`을 생성자로 작게 주입해도, `AudioMemoryCache`를 직접 건드리지 않고
    /// `AudioRepository.prefetch`만 반복 호출하는 것만으로 entry LRU가 실제로 발동하는지 검증한다.
    func test_repository를_통한_prefetch만으로도_memory_entry_상한을_넘으면_LRU가_발동한다() async throws {
        let memory = AudioMemoryCache(countLimit: 2)
        let disk = AudioDiskCache(directory: directory)

        await withDependencies {
            $0.audioMemoryCache = memory
            $0.audioDiskCache = disk
            $0.httpClient = StubHTTPClient { url in Data(url.absoluteString.utf8) }
        } operation: {
            await AudioRepository.liveValue.prefetch([
                (term: "old", audioUrl: "https://example.com/old.mp3"),
                (term: "new", audioUrl: "https://example.com/new.mp3"),
                (term: "newest", audioUrl: "https://example.com/newest.mp3")
            ])
        }

        let old = await memory.url(for: "old")
        let new = await memory.url(for: "new")
        let newest = await memory.url(for: "newest")

        XCTAssertNil(old, "repository만 거쳤어도 memory entry 상한 초과 시 가장 오래된 term이 제거돼야 한다")
        XCTAssertNotNil(new)
        XCTAssertNotNil(newest)
        XCTAssertNotNil(disk.url(for: "old"), "memory에서 밀려나도 disk엔 여전히 남아있어야 한다")
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
