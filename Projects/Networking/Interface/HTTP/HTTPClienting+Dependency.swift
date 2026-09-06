import Foundation

import Dependencies

public extension DependencyValues {
    var httpClient: any HTTPClienting {
        get { self[HTTPClientKey.self] }
        set { self[HTTPClientKey.self] = newValue }
    }
}

public enum HTTPClientKey: TestDependencyKey {
    public static let testValue: any HTTPClienting = unimplemented(
        "\(Self.self).testValue",
        placeholder: NoopHTTPClient()
    )
}

private struct NoopHTTPClient: HTTPClienting {
    func request<T: Decodable>(_ requestable: any Requestable) async throws -> T {
        throw NetworkError.invalidRequest
    }

    func request(_ requestable: any Requestable) async throws {
        throw NetworkError.invalidRequest
    }

    func data(from url: URL) async throws -> Data {
        throw NetworkError.invalidRequest
    }
}
