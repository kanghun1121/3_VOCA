import XCTest

@testable import Data

final class AudioDiskCacheTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = URL.temporaryDirectory.appending(path: "AudioDiskCacheTests-\(UUID().uuidString)")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    func test_저장_후_조회하면_저장한_URL과_내용을_그대로_돌려준다() throws {
        let sut = AudioDiskCache(directory: directory)
        let data = Data("hello".utf8)

        let storedURL = try sut.store(data, for: "apple")

        XCTAssertEqual(sut.url(for: "apple"), storedURL)
        XCTAssertEqual(try Data(contentsOf: storedURL), data)
    }

    func test_저장한_적_없는_term은_조회_시_nil을_반환한다() {
        let sut = AudioDiskCache(directory: directory)

        XCTAssertNil(sut.url(for: "never-stored"))
    }

    func test_공백이나_슬래시가_포함된_term도_저장과_조회에_성공한다() throws {
        let sut = AudioDiskCache(directory: directory)
        let data = Data("phrasal verb".utf8)

        let storedURL = try sut.store(data, for: "look up")

        XCTAssertEqual(sut.url(for: "look up"), storedURL)
        XCTAssertEqual(try Data(contentsOf: storedURL), data)

        let storedURL2 = try sut.store(Data("a over b".utf8), for: "a/b")
        XCTAssertEqual(sut.url(for: "a/b"), storedURL2)
    }

    func test_서로_다른_term은_서로_다른_파일에_저장되어_내용이_섞이지_않는다() throws {
        let sut = AudioDiskCache(directory: directory)

        let urlA = try sut.store(Data("A".utf8), for: "apple")
        let urlB = try sut.store(Data("B".utf8), for: "banana")

        XCTAssertNotEqual(urlA, urlB)
        XCTAssertEqual(try Data(contentsOf: urlA), Data("A".utf8))
        XCTAssertEqual(try Data(contentsOf: urlB), Data("B".utf8))
    }

    func test_동일한_term에_두_번_저장하면_마지막_내용으로_수렴한다() throws {
        let sut = AudioDiskCache(directory: directory)

        _ = try sut.store(Data("first".utf8), for: "apple")
        let latestURL = try sut.store(Data("second".utf8), for: "apple")

        XCTAssertEqual(sut.url(for: "apple"), latestURL)
        XCTAssertEqual(try Data(contentsOf: latestURL), Data("second".utf8))
    }

    func test_존재하지_않는_디렉터리를_주입해도_첫_저장에서_자동으로_생성된다() throws {
        let sut = AudioDiskCache(directory: directory)
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.path(percentEncoded: false)))

        _ = try sut.store(Data("hello".utf8), for: "apple")

        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.path(percentEncoded: false)))
    }

    // MARK: - staleness

    func test_동일_remoteURLString으로_조회하면_히트다() throws {
        let sut = AudioDiskCache(directory: directory)
        let storedURL = try sut.store(Data("apple-mp3".utf8), for: "apple", remoteURLString: "https://example.com/apple.mp3")

        XCTAssertEqual(sut.url(for: "apple", expecting: "https://example.com/apple.mp3"), storedURL)
    }

    func test_remoteURLString이_다르면_stale로_취급해_nil을_반환한다() throws {
        let sut = AudioDiskCache(directory: directory)
        _ = try sut.store(Data("apple-mp3".utf8), for: "apple", remoteURLString: "https://example.com/apple.mp3")

        XCTAssertNil(sut.url(for: "apple", expecting: "https://example.com/new-apple.mp3"))
    }

    func test_한번도_저장한_적_없는_term은_remoteURLString과_무관하게_미스다() {
        let sut = AudioDiskCache(directory: directory)

        XCTAssertNil(sut.url(for: "ghost", expecting: "https://example.com/ghost.mp3"))
    }

    // MARK: - recency (LRU 판단 기준)

    func test_히트_조회는_recency_mtime을_현재_시각으로_갱신한다() throws {
        let sut = AudioDiskCache(directory: directory)
        let storedURL = try sut.store(Data("apple-mp3".utf8), for: "apple", remoteURLString: "https://example.com/apple.mp3")
        let oldDate = Date(timeIntervalSince1970: 0)
        setModificationDate(oldDate, for: storedURL)

        XCTAssertNotNil(sut.url(for: "apple", expecting: "https://example.com/apple.mp3"))

        XCTAssertNotEqual(modificationDate(of: storedURL), oldDate)
    }

    func test_stale_조회는_recency_mtime을_갱신하지_않는다() throws {
        let sut = AudioDiskCache(directory: directory)
        let storedURL = try sut.store(Data("apple-mp3".utf8), for: "apple", remoteURLString: "https://example.com/apple.mp3")
        let oldDate = Date(timeIntervalSince1970: 0)
        setModificationDate(oldDate, for: storedURL)

        XCTAssertNil(sut.url(for: "apple", expecting: "https://example.com/different.mp3"))

        XCTAssertEqual(modificationDate(of: storedURL), oldDate)
    }

    // MARK: - 용량 상한 (LRU 삭제)

    func test_용량_상한_이하일_때는_기존_파일을_삭제하지_않는다() throws {
        let sut = AudioDiskCache(directory: directory, sizeLimitBytes: 1_000)

        let url1 = try sut.store(Data(repeating: 0, count: 100), for: "apple", remoteURLString: "https://example.com/apple.mp3")
        let url2 = try sut.store(Data(repeating: 0, count: 100), for: "banana", remoteURLString: "https://example.com/banana.mp3")

        XCTAssertTrue(FileManager.default.fileExists(atPath: url1.path(percentEncoded: false)))
        XCTAssertTrue(FileManager.default.fileExists(atPath: url2.path(percentEncoded: false)))
    }

    func test_용량_상한을_초과하면_가장_오래된_파일부터_필요한_만큼만_삭제한다() throws {
        let sut = AudioDiskCache(directory: directory, sizeLimitBytes: 250)

        let oldURL = try sut.store(Data(repeating: 0, count: 100), for: "old", remoteURLString: "https://example.com/old.mp3")
        setModificationDate(Date(timeIntervalSinceNow: -100), for: oldURL)
        let newURL = try sut.store(Data(repeating: 0, count: 100), for: "new", remoteURLString: "https://example.com/new.mp3")
        setModificationDate(Date(), for: newURL)

        // 세 번째 저장으로 총 용량(300B)이 상한(250B)을 넘어 eviction이 발생한다.
        let newestURL = try sut.store(Data(repeating: 0, count: 100), for: "newest", remoteURLString: "https://example.com/newest.mp3")

        XCTAssertFalse(FileManager.default.fileExists(atPath: oldURL.path(percentEncoded: false)), "가장 오래된 파일이 삭제돼야 한다")
        XCTAssertTrue(FileManager.default.fileExists(atPath: newURL.path(percentEncoded: false)), "필요한 만큼만 삭제되어야 한다")
        XCTAssertTrue(FileManager.default.fileExists(atPath: newestURL.path(percentEncoded: false)))
    }

    func test_삭제되는_파일의_sourceurl_sidecar도_함께_삭제된다() throws {
        let sut = AudioDiskCache(directory: directory, sizeLimitBytes: 150)

        let oldURL = try sut.store(Data(repeating: 0, count: 100), for: "old", remoteURLString: "https://example.com/old.mp3")
        setModificationDate(Date(timeIntervalSinceNow: -100), for: oldURL)
        let oldSidecarURL = oldURL.deletingPathExtension().appendingPathExtension("sourceurl")
        XCTAssertTrue(FileManager.default.fileExists(atPath: oldSidecarURL.path(percentEncoded: false)))

        _ = try sut.store(Data(repeating: 0, count: 100), for: "new", remoteURLString: "https://example.com/new.mp3")

        XCTAssertFalse(FileManager.default.fileExists(atPath: oldSidecarURL.path(percentEncoded: false)))
    }

    func test_mp3_없이_sourceurl만_남은_고아_파일이_있어도_저장과_정리는_크래시_없이_동작한다() throws {
        let sut = AudioDiskCache(directory: directory, sizeLimitBytes: 1_000_000)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let orphanSidecar = directory.appending(path: "orphan.sourceurl")
        try Data("https://example.com/orphan.mp3".utf8).write(to: orphanSidecar)

        XCTAssertNoThrow(try sut.store(Data("apple-mp3".utf8), for: "apple", remoteURLString: "https://example.com/apple.mp3"))
    }

    // MARK: - helpers

    private func setModificationDate(_ date: Date, for url: URL) {
        try? FileManager.default.setAttributes([.modificationDate: date], ofItemAtPath: url.path(percentEncoded: false))
    }

    private func modificationDate(of url: URL) -> Date? {
        try? FileManager.default.attributesOfItem(atPath: url.path(percentEncoded: false))[.modificationDate] as? Date
    }
}
