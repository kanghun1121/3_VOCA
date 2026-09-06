import Foundation

import NetworkingInterface

public struct HTTPClient<Interceptor: HTTPInterceptor>: HTTPClienting {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let interceptor: Interceptor
    private let logger = NetworkLogger()

    public init(
        interceptor: Interceptor,
        session: URLSession = .shared,
        decoder: JSONDecoder? = nil
    ) {
        self.interceptor = interceptor
        self.session = session
        self.decoder = decoder ?? {
            let d = JSONDecoder()
            d.keyDecodingStrategy = .convertFromSnakeCase
            return d
        }()
    }

    public func request<T: Decodable>(_ requestable: any Requestable) async throws -> T {
        let (data, response) = try await perform(requestable)
        try validate(response, data: data)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }

    public func request(_ requestable: any Requestable) async throws {
        let (data, response) = try await perform(requestable)
        try validate(response, data: data)
        _ = data
    }

    public func data(from url: URL) async throws -> Data {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = HTTPMethod.get.rawValue

        logger.logRequest(urlRequest)

        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            logger.logError(error, context: url.absoluteString)
            throw NetworkError.requestFailed(error)
        }

        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        logger.logResponse(response, statusCode: statusCode, data: data)
        try validate(response, data: data)

        return data
    }

    private func perform(_ requestable: any Requestable) async throws -> (Data, URLResponse) {
        let (data, response) = try await execute(requestable)

        if let http = response as? HTTPURLResponse, http.statusCode == 401,
           await interceptor.retry(dueTo: NetworkError.httpError(statusCode: 401, data: data), response: http) {
            return try await execute(requestable)
        }

        return (data, response)
    }

    private func execute(_ requestable: any Requestable) async throws -> (Data, URLResponse) {
        var urlRequest: URLRequest
        do {
            urlRequest = try requestable.makeURLRequest()
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.invalidRequest
        }

        if requestable.requiresAuthentication {
            do {
                urlRequest = try await interceptor.adapt(urlRequest)
            } catch {
                throw NetworkError.invalidRequest
            }
        }

        logger.logRequest(urlRequest)

        do {
            let (data, response) = try await session.data(for: urlRequest)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            logger.logResponse(response, statusCode: statusCode, data: data)
            return (data, response)
        } catch {
            logger.logError(error, context: urlRequest.url?.absoluteString ?? "unknown")
            throw NetworkError.requestFailed(error)
        }
    }

    private func validate(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw NetworkError.httpError(statusCode: http.statusCode, data: data)
        }
    }
}

// MARK: - NoopInterceptor 기본 편의 이니셜라이저

public extension HTTPClient where Interceptor == NoopInterceptor {
    init(session: URLSession = .shared, decoder: JSONDecoder? = nil) {
        self.init(interceptor: NoopInterceptor(), session: session, decoder: decoder)
    }
}
