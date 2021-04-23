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

    func rxDataRequest1(_ request: URLRequest) -> AnyPublisher<Data, ReactiveAPIError> {
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
                    let retryRequest = authenticator.authenticate1(session: self.session,
                                                                  request: request,
                                                                  response: response,
                                                                  data: data)
                else { throw error }

                return retryRequest
            }
            .mapError { ReactiveAPIError.map($0) }
            .eraseToAnyPublisher()
    }

    func rxDataRequest1<D: Decodable>(_ request: URLRequest) -> AnyPublisher<D, ReactiveAPIError> {
        return rxDataRequest1(request)
            .tryMap { data in try self.decoder.decode(D.self, from: data) }
            .mapError { error in
                guard let decodingError = error as? DecodingError else {
                    return ReactiveAPIError.map(error)
                }
                return ReactiveAPIError.decodingError1(decodingError)
            }
            .eraseToAnyPublisher()
    }

    func rxDataRequestDiscardingPayload1(_ request: URLRequest) -> AnyPublisher<Void, ReactiveAPIError> {
        return rxDataRequest1(request).tryMap { _ in () }
            .mapError { ReactiveAPIError.map($0) }
            .eraseToAnyPublisher()
    }
}

public extension ReactiveAPIProtocol { // TODO: refactoring!!!
    // body params as dictionary and generic response type
    func request1<D: Decodable>(_ method: ReactiveAPIHTTPMethod = .get,
                                url: URL,
                                headers: [String: Any?]? = nil,
                                queryParams: [String: Any?]? = nil,
                                bodyParams: [String: Any?]? = nil) -> AnyPublisher<D, ReactiveAPIError> {

        let closure = { () throws -> URLRequest in
            do {
                let request = try URLRequest.createForJSON(with: url,
                                                           method: method,
                                                           headers: headers,
                                                           queryParams: queryParams,
                                                           bodyParams: bodyParams,
                                                           queryStringTypeConverter: queryStringTypeConverter)
                return request
            } catch {
                throw error
            }
        }

        return Just(1)
            .tryMap { _ in try closure() }
            .mapError { ReactiveAPIError.map($0) }
            .flatMap { rxDataRequest1($0) }
            .mapError { ReactiveAPIError.map($0) }
            .eraseToAnyPublisher()
    }

    // body params as encodable and generic response type
    func request1<E: Encodable, D: Decodable>(_ method: ReactiveAPIHTTPMethod = .get,
                                             url: URL,
                                             headers: [String: Any?]? = nil,
                                             queryParams: [String: Any?]? = nil,
                                             body: E? = nil) -> AnyPublisher<D, ReactiveAPIError> {
        let closure = { () throws -> URLRequest in
            do {
                let request = try URLRequest.createForJSON(with: url,
                                                           method: method,
                                                           headers: headers,
                                                           queryParams: queryParams,
                                                           body: body,
                                                           encoder: encoder,
                                                           queryStringTypeConverter: queryStringTypeConverter)
                return request
            } catch {
                throw error
            }
        }

        return Just(1)
            .tryMap { _ in try closure() }
            .mapError { ReactiveAPIError.map($0) }
            .flatMap { rxDataRequest1($0) }
            .mapError { ReactiveAPIError.map($0) }
            .eraseToAnyPublisher()
    }

    // body params as dictionary and void response type
    func request1(_ method: ReactiveAPIHTTPMethod = .get,
                  url: URL,
                  headers: [String: Any?]? = nil,
                  queryParams: [String: Any?]? = nil,
                  bodyParams: [String: Any?]? = nil) -> AnyPublisher<Void, ReactiveAPIError> {
        let closure = { () throws -> AnyPublisher<Void, ReactiveAPIError> in
            do {
                let request = try URLRequest.createForJSON(with: url,
                                                           method: method,
                                                           headers: headers,
                                                           queryParams: queryParams,
                                                           bodyParams: bodyParams,
                                                           queryStringTypeConverter: queryStringTypeConverter)
                return rxDataRequestDiscardingPayload1(request)
            } catch {
                throw error
            }
        }

        return Just(1)
            .tryMap { _ in try closure() }
            .mapError { ReactiveAPIError.map($0) }
            .eraseToAnyPublisher()
    }

    // body params as encodable and void response type
    func request1<E: Encodable>(_ method: ReactiveAPIHTTPMethod = .get,
                                url: URL,
                                headers: [String: Any?]? = nil,
                                queryParams: [String: Any?]? = nil,
                                body: E? = nil) -> AnyPublisher<Void, ReactiveAPIError> {

        let closure = { () throws -> AnyPublisher<Void, ReactiveAPIError> in
            do {
                let request = try URLRequest.createForJSON(with: url,
                                                           method: method,
                                                           headers: headers,
                                                           queryParams: queryParams,
                                                           body: body,
                                                           encoder: encoder,
                                                           queryStringTypeConverter: queryStringTypeConverter)
                return rxDataRequestDiscardingPayload1(request)
            } catch {
                throw error
            }
        }

        return Just(1)
            .tryMap { _ in try closure() }
            .mapError { ReactiveAPIError.map($0) }
            .eraseToAnyPublisher()

    }
}
