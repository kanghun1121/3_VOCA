import Foundation

import Dependencies

/// mp3를 임시 디렉터리에 보관하는 계층. 저장 위치와 파일명 규칙, 존재 여부 판단만 책임진다.
///
/// 저장은 항상 원자적(.atomic)이다. 덕분에 "경로에 파일이 있다 = 완전한 mp3다"가 불변식으로
/// 성립하고, 동일 term에 대한 동시 중복 저장이 발생해도 파일이 깨지지 않는다.
struct AudioDiskCache: Sendable {
    private let directory: URL

    init(directory: URL = URL.temporaryDirectory.appending(path: "AudioCache", directoryHint: .isDirectory)) {
        self.directory = directory
    }

    /// 디스크에 완성된 파일이 있으면 그 URL을, 없으면 nil을 돌려준다(miss는 오류가 아니다).
    func url(for term: String) -> URL? {
        let fileURL = fileURL(for: term)
        guard FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) else {
            return nil
        }
        return fileURL
    }

    /// 바이트를 원자적으로 저장하고 저장된 파일 URL을 돌려준다(저장 실패는 오류로 던진다).
    @discardableResult
    func store(_ data: Data, for term: String) throws -> URL {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = fileURL(for: term)
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }

    /// term에는 공백/슬래시가 섞일 수 있어(구동사 등) 그대로 파일명에 쓰면 경로가 깨진다.
    /// 퍼센트 인코딩은 결정적이고 충돌이 없어 term ↔ 파일명이 1:1로 대응한다.
    private func fileURL(for term: String) -> URL {
        let name = term.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? term
        return directory.appending(path: "\(name).mp3")
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
