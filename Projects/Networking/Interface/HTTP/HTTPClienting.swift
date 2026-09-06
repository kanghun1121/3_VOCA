import Foundation

public protocol HTTPClienting {
    func request<T: Decodable>(_ requestable: any Requestable) async throws -> T
    func request(_ requestable: any Requestable) async throws
    /// 서버가 내려준 완성형 절대 URL에서 raw 바이트를 받는다. mp3 같은 바이너리 리소스처럼
    /// Requestable의 baseURL+path 조합으로 표현할 수 없는(쿼리스트링에 서명 토큰이 포함될
    /// 수도 있는) URL을 위한 경로다. 인터셉터를 거치지 않는다.
    func data(from url: URL) async throws -> Data
}
