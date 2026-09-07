import Foundation

import NetworkingInterface

import Dependencies

/// 서버에 있는 mp3 원본을 바이트로 받아오는 계층. URLSession을 직접 쓰지 않고 `httpClient`
/// 의존성에 위임한다. mp3 URL은 서버가 내려준 완성형 절대 URL(쿼리스트링에 서명 토큰이
/// 포함될 수 있음)이라 Requestable의 baseURL+path 조합에 태울 수 없으므로 data(from:)
/// 경로를 쓴다. 인증이 필요 없는 공개 리소스라 무인증 HTTPClient를 쓴다. 실패를 삼키지
/// 않고 그대로 던진다 — "실패한 term은 건너뛴다"는 정책은 오케스트레이션
/// (AudioRepository+Live.swift)의 몫이다.
///
/// `httpClient`는 호출 시점에 매번 새로 읽는다(구조체 프로퍼티로 한 번 캡처해 두지 않는다) —
/// `liveValue`는 프로세스 전체에서 딱 한 번만 평가되는 `static let`이라, 만약 생성 시점에
/// 캡처해버리면 이후 테스트가 `withDependencies { $0.httpClient = ... }`로 주입한 스텁이
/// 반영되지 않는다.
struct AudioRemoteDataSource: Sendable {
    func download(from remoteURL: URL) async throws -> Data {
        @Dependency(\.httpClient) var httpClient
        return try await httpClient.data(from: remoteURL)
    }
}

extension AudioRemoteDataSource: DependencyKey {
    static let liveValue = AudioRemoteDataSource()
}

extension AudioRemoteDataSource: TestDependencyKey {
    static let testValue = AudioRemoteDataSource()
}

extension DependencyValues {
    var audioRemoteDataSource: AudioRemoteDataSource {
        get { self[AudioRemoteDataSource.self] }
        set { self[AudioRemoteDataSource.self] = newValue }
    }
}
