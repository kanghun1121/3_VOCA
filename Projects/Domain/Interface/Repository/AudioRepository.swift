import Foundation

import Dependencies

/// 단어 발음 mp3 리소스를 추상화한 포트. 실제 구현은 Data 모듈에서 제공한다.
public struct AudioRepository: Sendable {
    public var prefetch: @Sendable (_ words: [(term: String, audioUrl: String)]) async -> Void
    public var fetchURL: @Sendable (_ term: String, _ audioUrl: String) async -> URL?
    public var url: @Sendable (_ term: String) async -> URL?

    public init(
        prefetch: @escaping @Sendable (_ words: [(term: String, audioUrl: String)]) async -> Void,
        fetchURL: @escaping @Sendable (_ term: String, _ audioUrl: String) async -> URL?,
        url: @escaping @Sendable (_ term: String) async -> URL?
    ) {
        self.prefetch = prefetch
        self.fetchURL = fetchURL
        self.url = url
    }
}

extension AudioRepository: TestDependencyKey {
    public static let testValue = AudioRepository(
        prefetch: unimplemented("\(Self.self).prefetch", placeholder: ()),
        fetchURL: unimplemented("\(Self.self).fetchURL", placeholder: nil),
        url: unimplemented("\(Self.self).url", placeholder: nil)
    )
}

public extension DependencyValues {
    var audioRepository: AudioRepository {
        get { self[AudioRepository.self] }
        set { self[AudioRepository.self] = newValue }
    }
}
