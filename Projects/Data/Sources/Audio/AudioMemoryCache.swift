import Foundation

import Dependencies

/// term(단어)별로 "완성된 mp3 파일이 준비됐다"는 사실을 메모리에 인덱싱하는 계층.
///
/// mp3 바이트 자체를 들고 있지 않는다 — 재생은 AVPlayerItem(url:)로 이뤄지고 AVPlayer는
/// 파일을 직접 스트리밍하므로, 메모리의 바이트는 결국 다시 디스크에 써야만 재생에 쓸 수 있어
/// 아무것도 아끼지 못한다. 이 계층이 실제로 아끼는 건 조회 1회당 디스크 존재 확인
/// (FileManager.fileExists) 왕복이다.
///
/// 그래서 상한은 MB가 아니라 entry 개수로 잰다 — 항목 하나가 term(String)+URL 한 쌍이라
/// 수백 바이트 수준이고, 상한의 목적도 메모리 절약이 아니라 세션이 길어질 때 딕셔너리가
/// 무한정 자라는 걸 막는 것이다. 초과분은 가장 오래 접근되지 않은 term부터 제거한다.
///
/// remoteURLString도 같이 기억해두면 staleness 판정에 쓸 수 있다 — 이게 없던 예전 구현은
/// 세션 중 서버가 같은 term에 다른 URL을 내려줘도 메모리 히트가 이를 무시하는 잠재 버그가
/// 있었다.
actor AudioMemoryCache {
    private struct Entry {
        var url: URL
        var remoteURLString: String?
    }

    private var entries: [String: Entry] = [:]
    private var accessOrder: [String] = [] // 오래된 것이 앞쪽
    private let countLimit: Int

    init(countLimit: Int = 500) {
        self.countLimit = countLimit
    }

    /// remoteURLString을 모르는 호출부(순수 재생 조회) 전용 — staleness 판정은 하지 않는다.
    func url(for term: String) -> URL? {
        guard let entry = entries[term] else { return nil }
        touch(term)
        return entry.url
    }

    /// 저장 당시의 remoteURLString과 다르면(staleness) nil을 돌려준다. 미스/stale 판정 시에는
    /// recency를 갱신하지 않는다.
    func url(for term: String, expecting remoteURLString: String) -> URL? {
        guard let entry = entries[term], entry.remoteURLString == remoteURLString else { return nil }
        touch(term)
        return entry.url
    }

    /// "다운로드 중"이라는 상태를 갖지 않는다 — 오직 "완성됨"만 기록한다. 동시에 같은 term이
    /// 여러 번 기록돼도(동시 프리페치 중복) 항상 같은 값이 쓰이므로 안전하다.
    func markReady(_ term: String, url: URL, remoteURLString: String? = nil) {
        if entries[term] == nil {
            accessOrder.append(term)
        } else {
            touch(term)
        }
        entries[term] = Entry(url: url, remoteURLString: remoteURLString)
        evictIfNeeded()
    }

    private func touch(_ term: String) {
        if let index = accessOrder.firstIndex(of: term) {
            accessOrder.remove(at: index)
        }
        accessOrder.append(term)
    }

    private func evictIfNeeded() {
        while entries.count > countLimit, !accessOrder.isEmpty {
            let oldest = accessOrder.removeFirst()
            entries.removeValue(forKey: oldest)
        }
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
