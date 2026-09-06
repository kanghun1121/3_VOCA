import Foundation

import Dependencies

/// term(단어)별로 "완성된 mp3 파일이 준비됐다"는 사실을 메모리에 인덱싱하는 계층.
///
/// mp3 바이트 자체를 들고 있지 않는다 — 재생은 AVPlayerItem(url:)로 이뤄지고 AVPlayer는
/// 파일을 직접 스트리밍하므로, 메모리의 바이트는 결국 다시 디스크에 써야만 재생에 쓸 수 있어
/// 아무것도 아끼지 못한다. 이 계층이 실제로 아끼는 건 조회 1회당 디스크 존재 확인
/// (FileManager.fileExists) 왕복이다.
///
/// "다운로드 중"이라는 상태를 갖지 않는다 — 오직 "완성됨"만 기록한다. 동시에 같은 term이
/// 여러 번 기록돼도(동시 프리페치 중복) 항상 같은 값이 쓰이므로 안전하다.
actor AudioMemoryCache {
    private var readyURLs: [String: URL] = [:]

    func url(for term: String) -> URL? {
        readyURLs[term]
    }

    func markReady(_ term: String, url: URL) {
        readyURLs[term] = url
    }
}

extension AudioMemoryCache: DependencyKey {
    static let liveValue = AudioMemoryCache()
}

extension DependencyValues {
    var audioMemoryCache: AudioMemoryCache {
        get { self[AudioMemoryCache.self] }
        set { self[AudioMemoryCache.self] = newValue }
    }
}
