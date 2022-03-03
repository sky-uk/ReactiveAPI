import Foundation

public typealias ReactiveAPITypeConverter = (_ value: Any?) -> String?

public protocol ReactiveAPIProtocol {
    var baseUrl: URL { get }
    var session: URLSession { get }
    var decoder: ReactiveAPIDecoder { get }
    var encoder: JSONEncoder { get }
    var authenticator: ReactiveAPIAuthenticator? { get set }
    var requestInterceptors: [ReactiveAPIRequestInterceptor] { get set }
    var queryStringTypeConverter: ReactiveAPITypeConverter? { get set }
    var cache: ReactiveAPICache? { get set }
    func absoluteURL(_ endpoint: String) -> URL
}

public protocol ReactiveAPIDecoder {
    func decode<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable
}

extension JSONDecoder: ReactiveAPIDecoder {}

extension ReactiveAPIProtocol {
    public func absoluteURL(_ endpoint: String) -> URL {
        return baseUrl.appendingPathComponent(endpoint)
    }

    @discardableResult
    func rxDataRequest(_ request: URLRequest) async throws -> Data {
        do {
            let (request, response, data) = try await session.fetch(request, interceptors: requestInterceptors)
            if let cache = self.cache,
               let urlCache = self.session.configuration.urlCache,
               let cachedResponse = cache.cache(response,
                                                request: request,
                                                data: data) {
                urlCache.storeCachedResponse(cachedResponse,
                                             for: request)
            }

            return data

        } catch(let error) {
            guard
                let authenticator = self.authenticator,
                case let ReactiveAPIError.httpError(request, response, data) = error,
                let retryRequest = try await authenticator.authenticate(session: self.session,
                                                              request: request,
                                                              response: response,
                                                              data: data)
            else { throw error }

            return retryRequest
        }
    }

    @discardableResult
    func rxDataRequest<D: Decodable>(_ request: URLRequest) async throws -> D {
        let data = try await rxDataRequest(request)
        do {
            let decoded = try self.decoder.decode(D.self, from: data)
            return decoded
        } catch {
            guard let underlyingError = error as? DecodingError
            else { throw error }

            let decodingError = ReactiveAPIError.decodingError(underlyingError, data: data)
            throw decodingError
        }
    }

    func rxDataRequestDiscardingPayload(_ request: URLRequest) async throws {
        try await rxDataRequest(request)
    }
}

public extension ReactiveAPIProtocol {
    // body params as dictionary and generic response type
    func request<D: Decodable>(_ method: ReactiveAPIHTTPMethod = .get,
                               url: URL,
                               headers: [String: Any?]? = nil,
                               queryParams: [String: Any?]? = nil,
                               bodyParams: [String: Any?]? = nil) async throws -> D {
        let request = try URLRequest.createForJSON(with: url,
                                                   method: method,
                                                   headers: headers,
                                                   queryParams: queryParams,
                                                   bodyParams: bodyParams,
                                                   queryStringTypeConverter: queryStringTypeConverter)
        return try await rxDataRequest(request)
    }

    // body params as encodable and generic response type
    func request<E: Encodable, D: Decodable>(_ method: ReactiveAPIHTTPMethod = .get,
                                             url: URL,
                                             headers: [String: Any?]? = nil,
                                             queryParams: [String: Any?]? = nil,
                                             body: E? = nil) async throws -> D {
        let request = try URLRequest.createForJSON(with: url,
                                                   method: method,
                                                   headers: headers,
                                                   queryParams: queryParams,
                                                   body: body,
                                                   encoder: encoder,
                                                   queryStringTypeConverter: queryStringTypeConverter)
        return try await rxDataRequest(request)
    }

    // body params as dictionary and void response type
    func request(_ method: ReactiveAPIHTTPMethod = .get,
                 url: URL,
                 headers: [String: Any?]? = nil,
                 queryParams: [String: Any?]? = nil,
                 bodyParams: [String: Any?]? = nil) async throws -> Void {
        let request = try URLRequest.createForJSON(with: url,
                                                   method: method,
                                                   headers: headers,
                                                   queryParams: queryParams,
                                                   bodyParams: bodyParams,
                                                   queryStringTypeConverter: queryStringTypeConverter)
        return try await rxDataRequestDiscardingPayload(request)
    }

    // body params as encodable and void response type
    func request<E: Encodable>(_ method: ReactiveAPIHTTPMethod = .get,
                               url: URL,
                               headers: [String: Any?]? = nil,
                               queryParams: [String: Any?]? = nil,
                               body: E? = nil) async throws -> Void {
        let request = try URLRequest.createForJSON(with: url,
                                                   method: method,
                                                   headers: headers,
                                                   queryParams: queryParams,
                                                   body: body,
                                                   encoder: encoder,
                                                   queryStringTypeConverter: queryStringTypeConverter)
        return try await rxDataRequestDiscardingPayload(request)
    }
}
