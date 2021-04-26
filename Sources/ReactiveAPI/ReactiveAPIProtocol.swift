import Foundation
import Combine

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

    func reactiveDataRequest(_ request: URLRequest) -> AnyPublisher<Data, ReactiveAPIError> {
        return session.fetch(request, interceptors: requestInterceptors)
            .tryMap { (request, response, data) -> Data in
                if let cache = self.cache,
                   let urlCache = self.session.configuration.urlCache,
                   let cachedResponse = cache.cache(response,
                                                    request: request,
                                                    data: data) {

                    urlCache.storeCachedResponse(cachedResponse,
                                                 for: request)

                }
                return data
            }
            .tryCatch { error -> AnyPublisher<Data, ReactiveAPIError> in
                guard
                    let authenticator = self.authenticator,
                    case let ReactiveAPIError.httpError(request, response, data) = error,
                    let retryRequest = authenticator.authenticate(session: self.session,
                                                                  request: request,
                                                                  response: response,
                                                                  data: data)
                else { throw error }

                return retryRequest
            }
            .mapError { ReactiveAPIError.map($0) }
            .eraseToAnyPublisher()
    }

    func reactiveDataRequest<D: Decodable>(_ request: URLRequest) -> AnyPublisher<D, ReactiveAPIError> {
        return reactiveDataRequest(request)
            .tryMap { data in try self.decoder.decode(D.self, from: data) }
            .mapError { error in
                guard let decodingError = error as? DecodingError else {
                    return ReactiveAPIError.map(error)
                }
                return ReactiveAPIError.decodingError(decodingError)
            }
            .eraseToAnyPublisher()
    }

    func reactiveDataRequestDiscardingPayload(_ request: URLRequest) -> AnyPublisher<Void, ReactiveAPIError> {
        return reactiveDataRequest(request).tryMap { _ in () }
            .mapError { ReactiveAPIError.map($0) }
            .eraseToAnyPublisher()
    }
}

public extension ReactiveAPIProtocol { // TODO: refactoring!!!
    // body params as dictionary and generic response type
    func request<D: Decodable>(_ method: ReactiveAPIHTTPMethod = .get,
                               url: URL,
                               headers: [String: Any?]? = nil,
                               queryParams: [String: Any?]? = nil,
                               bodyParams: [String: Any?]? = nil) -> AnyPublisher<D, ReactiveAPIError> {

        let closure = { () throws -> URLRequest in
            do {
                return try URLRequest.createForJSON(with: url,
                                                    method: method,
                                                    headers: headers,
                                                    queryParams: queryParams,
                                                    bodyParams: bodyParams,
                                                    queryStringTypeConverter: queryStringTypeConverter)
            } catch {
                throw error
            }
        }

        return Just(1)
            .tryMap { _ in try closure() }
            .mapError { ReactiveAPIError.map($0) }
            .flatMap { reactiveDataRequest($0) }
            .mapError { ReactiveAPIError.map($0) }
            .eraseToAnyPublisher()
    }

    // body params as encodable and generic response type
    //NOT USED
    func request<E: Encodable, D: Decodable>(_ method: ReactiveAPIHTTPMethod = .get,
                                             url: URL,
                                             headers: [String: Any?]? = nil,
                                             queryParams: [String: Any?]? = nil,
                                             body: E? = nil) -> AnyPublisher<D, ReactiveAPIError> {
        let closure = { () throws -> URLRequest in
            do {
                return try URLRequest.createForJSON(with: url,
                                                    method: method,
                                                    headers: headers,
                                                    queryParams: queryParams,
                                                    body: body,
                                                    encoder: encoder,
                                                    queryStringTypeConverter: queryStringTypeConverter)
            } catch {
                throw error
            }
        }

        return Just(1)
            .tryMap { _ in try closure() }
            .mapError { ReactiveAPIError.map($0) }
            .flatMap { reactiveDataRequest($0) }
            .mapError { ReactiveAPIError.map($0) }
            .eraseToAnyPublisher()
    }

    // body params as dictionary and void response type
    //NOT USED
    func request(_ method: ReactiveAPIHTTPMethod = .get,
                 url: URL,
                 headers: [String: Any?]? = nil,
                 queryParams: [String: Any?]? = nil,
                 bodyParams: [String: Any?]? = nil) -> AnyPublisher<Void, ReactiveAPIError> {
        let closure = { () throws -> URLRequest in
            do {
                return try URLRequest.createForJSON(with: url,
                                                    method: method,
                                                    headers: headers,
                                                    queryParams: queryParams,
                                                    bodyParams: bodyParams,
                                                    queryStringTypeConverter: queryStringTypeConverter)
            } catch {
                throw error
            }
        }

        return Just(1)
            .tryMap { _ in try closure() }
            .mapError { ReactiveAPIError.map($0) }
            .flatMap { reactiveDataRequestDiscardingPayload($0) }
            .eraseToAnyPublisher()
    }

    // body params as encodable and void response type
    //NOT USED
    func request<E: Encodable>(_ method: ReactiveAPIHTTPMethod = .get,
                               url: URL,
                               headers: [String: Any?]? = nil,
                               queryParams: [String: Any?]? = nil,
                               body: E? = nil) -> AnyPublisher<Void, ReactiveAPIError> {

        let closure = { () throws -> URLRequest in
            do {
                return try URLRequest.createForJSON(with: url,
                                                    method: method,
                                                    headers: headers,
                                                    queryParams: queryParams,
                                                    body: body,
                                                    encoder: encoder,
                                                    queryStringTypeConverter: queryStringTypeConverter)
            } catch {
                throw error
            }
        }

        return Just(1)
            .tryMap { _ in try closure() }
            .mapError { ReactiveAPIError.map($0) }
            .flatMap { reactiveDataRequestDiscardingPayload($0) }
            .eraseToAnyPublisher()

    }
}
