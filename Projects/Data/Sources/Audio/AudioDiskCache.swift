import Foundation

import Dependencies

/// mp3를 Caches 디렉터리에 보관하는 계층. 저장 위치, 파일명 규칙, 존재 여부 판단, staleness
/// 판정, 용량 상한(LRU) 관리를 책임진다.
///
/// 저장은 항상 원자적(.atomic)이다. 덕분에 "경로에 파일이 있다 = 완전한 mp3다"가 불변식으로
/// 성립하고, 동일 term에 대한 동시 중복 저장이 발생해도 파일이 깨지지 않는다.
///
/// `Library/Caches`를 쓰는 이유: `URL.temporaryDirectory`는 앱 부팅/sleep-resume마다 시스템이
/// 비울 수 있어 "세션을 넘어 유지되는 캐시"라는 의도와 맞지 않는다. Caches는 저장공간이 부족할
/// 때만, 그것도 앱이 실행 중이 아닐 때만 정리된다.
///
/// staleness는 term별로 나란히 저장되는 `.sourceurl` sidecar 파일(원격 URL 문자열 원문)로
/// 판정한다 — 저장 당시의 remoteURLString과 조회 시점 값이 다르면 miss로 취급해 호출부가
/// 자연히 재다운로드하도록 유도한다. 공유 JSON 매니페스트나 별도 actor를 쓰지 않는 이유는
/// term마다 파일이 독립적이라 동시 다운로드(TaskGroup)에도 레이스가 생기지 않기 때문이다.
///
/// LRU는 mp3 파일의 `contentModificationDate`를 조회 시점마다 touch해 "마지막 접근 시각"
/// 대용으로 쓴다 — 별도 접근 기록 저장소가 필요 없다. 단, 미스/stale 판정 시에는 touch하지
/// 않는다(실패 경로에서 recency가 갱신되면 안 됨).
struct AudioDiskCache: Sendable {
    private let directory: URL
    private let sizeLimitBytes: Int

    init(
        directory: URL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appending(path: "AudioCache", directoryHint: .isDirectory),
        sizeLimitBytes: Int = 50_000_000
    ) {
        self.directory = directory
        self.sizeLimitBytes = sizeLimitBytes
    }

    /// 디스크에 완성된 파일이 있으면 그 URL을, 없으면 nil을 돌려준다(miss는 오류가 아니다).
    /// remoteURLString을 모르는 호출부(순수 재생 조회) 전용 — staleness 판정은 하지 않는다.
    func url(for term: String) -> URL? {
        let fileURL = fileURL(for: term)
        guard FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) else {
            return nil
        }
        touch(fileURL)
        return fileURL
    }

    /// 저장 당시의 remoteURLString과 지금 넘어온 값이 다르면(staleness) nil을 돌려준다 —
    /// 호출부는 이걸 miss로 취급해 재다운로드하면 된다. 미스/stale 판정 시에는 recency를
    /// 갱신하지 않는다.
    func url(for term: String, expecting remoteURLString: String) -> URL? {
        let fileURL = fileURL(for: term)
        guard FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) else {
            return nil
        }
        guard let sidecarData = try? Data(contentsOf: sidecarURL(for: term)),
              let storedRemoteURLString = String(data: sidecarData, encoding: .utf8),
              storedRemoteURLString == remoteURLString
        else {
            return nil
        }
        touch(fileURL)
        return fileURL
    }

    /// 바이트를 원자적으로 저장하고 저장된 파일 URL을 돌려준다(저장 실패는 오류로 던진다).
    /// remoteURLString/용량 관리가 필요 없는 단순 저장 — staleness 판정을 쓰려면
    /// `store(_:for:remoteURLString:)`를 사용한다.
    @discardableResult
    func store(_ data: Data, for term: String) throws -> URL {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = fileURL(for: term)
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }

    /// mp3와 함께 원격 URL을 sidecar에 기록해 다음 조회에서 staleness 판정을 가능하게 하고,
    /// 저장 후 용량 상한을 초과했으면 오래된 항목부터 정리한다.
    @discardableResult
    func store(_ data: Data, for term: String, remoteURLString: String) throws -> URL {
        let fileURL = try store(data, for: term)
        try Data(remoteURLString.utf8).write(to: sidecarURL(for: term), options: .atomic)
        evictIfNeeded()
        return fileURL
    }

    /// term에는 공백/슬래시가 섞일 수 있어(구동사 등) 그대로 파일명에 쓰면 경로가 깨진다.
    /// 퍼센트 인코딩은 결정적이고 충돌이 없어 term ↔ 파일명이 1:1로 대응한다.
    private func fileURL(for term: String) -> URL {
        directory.appending(path: "\(encodedName(for: term)).mp3")
    }

    private func sidecarURL(for term: String) -> URL {
        directory.appending(path: "\(encodedName(for: term)).sourceurl")
    }

    private func encodedName(for term: String) -> String {
        term.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? term
    }

    private func touch(_ fileURL: URL) {
        try? FileManager.default.setAttributes(
            [.modificationDate: Date()],
            ofItemAtPath: fileURL.path(percentEncoded: false)
        )
    }

    /// 디렉터리의 mp3 총 용량이 상한을 넘으면 mtime이 오래된 것부터 삭제해 상한 이하로
    /// 수렴시킨다. 짝이 되는 `.sourceurl` sidecar도 함께 지운다. 이미 지워진 파일을 다시
    /// 지우려는 경우(동시 eviction) 등은 조용히 무시한다 — sidecar만 남은 고아 항목을 만나도
    /// 크래시하지 않는다.
    private func evictIfNeeded() {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return
        }

        let entries: [(url: URL, date: Date, size: Int)] = files
            .filter { $0.pathExtension == "mp3" }
            .compactMap { url in
                guard let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey]),
                      let date = values.contentModificationDate,
                      let size = values.fileSize
                else {
                    return nil
                }
                return (url, date, size)
            }

        var totalSize = entries.reduce(0) { $0 + $1.size }
        guard totalSize > sizeLimitBytes else { return }

        for entry in entries.sorted(by: { $0.date < $1.date }) {
            guard totalSize > sizeLimitBytes else { break }
            try? FileManager.default.removeItem(at: entry.url)
            try? FileManager.default.removeItem(at: entry.url.deletingPathExtension().appendingPathExtension("sourceurl"))
            totalSize -= entry.size
        }
    }
}

extension AudioDiskCache: DependencyKey {
    static let liveValue = AudioDiskCache()
}

extension DependencyValues {
    var audioDiskCache: AudioDiskCache {
        get { self[AudioDiskCache.self] }
        set { self[AudioDiskCache.self] = newValue }
    }
}
