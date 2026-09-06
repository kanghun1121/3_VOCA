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
}
