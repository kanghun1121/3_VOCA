import Foundation

import NetworkingInterface

/// 서버에 있는 mp3 원본을 바이트로 받아오는 계층. URLSession을 직접 쓰지 않고 주입받은
/// HTTPClienting에 위임한다. mp3 URL은 서버가 내려준 완성형 절대 URL(쿼리스트링에 서명
/// 토큰이 포함될 수 있음)이라 Requestable의 baseURL+path 조합에 태울 수 없으므로
/// data(from:) 경로를 쓴다. 인증이 필요 없는 공개 리소스라 무인증 HTTPClient를 주입받는다.
/// 실패를 삼키지 않고 그대로 던진다 — "실패한 term은 건너뛴다"는 정책은 오케스트레이션
/// (AudioRepository+Live.swift)의 몫이다.
struct AudioRemoteSource {
    private let httpClient: any HTTPClienting

    init(httpClient: any HTTPClienting) {
        self.httpClient = httpClient
    }

    func download(from remoteURL: URL) async throws -> Data {
        try await httpClient.data(from: remoteURL)
    }
}
