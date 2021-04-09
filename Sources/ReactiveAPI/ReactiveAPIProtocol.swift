import Foundation
import RxSwift
import Combine

public typealias ReactiveAPITypeConverter = (_ value: Any?) -> String?

public protocol ReactiveAPIProtocol {
    var baseUrl: URL { get }
    var session: Reactive<URLSession> { get }
    var session1: URLSession { get }
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

    func rxDataRequest(_ request: URLRequest) -> Single<Data> {
        return session.fetch(request, interceptors: requestInterceptors)
            .flatMap { request, response, data -> Observable<Data>  in
                if let cache = self.cache,
                   let urlCache = self.session.base.configuration.urlCache,
                   let cachedResponse = cache.cache(response,
                                                    request: request,
                                                    data: data) {
                    urlCache.storeCachedResponse(cachedResponse,
                                                 for: request)
                }

                return Observable.just(data)
            }
            .asSingle()
            .catchError { error -> Single<Data> in
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
    }

    func rxDataRequest1(_ request: URLRequest) -> AnyPublisher<Data, ReactiveAPIError> {
        return session1.fetch(request, interceptors: requestInterceptors)
            .tryMap { (request, response, data) -> Data in
                if let cache = self.cache,
                   let urlCache = self.session1.configuration.urlCache,
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
                    let retryRequest = authenticator.authenticate1(session: self.session1,
                                                                  request: request,
                                                                  response: response,
                                                                  data: data)
                else { throw error }

                return retryRequest
            }
            .mapError { ReactiveAPIError.map($0) }
            .eraseToAnyPublisher()
    }

    func rxDataRequest<D: Decodable>(_ request: URLRequest) -> Single<D> {
        return rxDataRequest(request).flatMap { data in
            do {
                let decoded = try self.decoder.decode(D.self, from: data)
                return Single.just(decoded)
            } catch {
                guard let underlyingError = error as? DecodingError
                else { return Single.error(error) }

                let decodingError = ReactiveAPIError.decodingError(underlyingError, data: data)
                return Single.error(decodingError)
            }
        }
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

    func rxDataRequestDiscardingPayload(_ request: URLRequest) -> Single<Void> {
        return rxDataRequest(request).map { _ in () }
    }

    func rxDataRequestDiscardingPayload1(_ request: URLRequest) -> AnyPublisher<Void, ReactiveAPIError> {
        return rxDataRequest1(request).tryMap { _ in () }
            .mapError { ReactiveAPIError.map($0) }
            .eraseToAnyPublisher()
    }
}

public extension ReactiveAPIProtocol {
    // body params as dictionary and generic response type
    func request<D: Decodable>(_ method: ReactiveAPIHTTPMethod = .get,
                               url: URL,
                               headers: [String: Any?]? = nil,
                               queryParams: [String: Any?]? = nil,
                               bodyParams: [String: Any?]? = nil) -> Single<D> {
        do {
            let request = try URLRequest.createForJSON(with: url,
                                                       method: method,
                                                       headers: headers,
                                                       queryParams: queryParams,
                                                       bodyParams: bodyParams,
                                                       queryStringTypeConverter: queryStringTypeConverter)
            return rxDataRequest(request)
        } catch {
            return Single.error(error)
        }
    }

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
    func request<E: Encodable, D: Decodable>(_ method: ReactiveAPIHTTPMethod = .get,
                                             url: URL,
                                             headers: [String: Any?]? = nil,
                                             queryParams: [String: Any?]? = nil,
                                             body: E? = nil) -> Single<D> {
        do {
            let request = try URLRequest.createForJSON(with: url,
                                                       method: method,
                                                       headers: headers,
                                                       queryParams: queryParams,
                                                       body: body,
                                                       encoder: encoder,
                                                       queryStringTypeConverter: queryStringTypeConverter)
            return rxDataRequest(request)
        } catch {
            return Single.error(error)
        }
    }

    // body params as dictionary and void response type
    func request(_ method: ReactiveAPIHTTPMethod = .get,
                 url: URL,
                 headers: [String: Any?]? = nil,
                 queryParams: [String: Any?]? = nil,
                 bodyParams: [String: Any?]? = nil) -> Single<Void> {
        do {
            let request = try URLRequest.createForJSON(with: url,
                                                       method: method,
                                                       headers: headers,
                                                       queryParams: queryParams,
                                                       bodyParams: bodyParams,
                                                       queryStringTypeConverter: queryStringTypeConverter)
            return rxDataRequestDiscardingPayload(request)
        } catch {
            return Single.error(error)
        }
    }

    // body params as encodable and void response type
    func request<E: Encodable>(_ method: ReactiveAPIHTTPMethod = .get,
                               url: URL,
                               headers: [String: Any?]? = nil,
                               queryParams: [String: Any?]? = nil,
                               body: E? = nil) -> Single<Void> {
        do {
            let request = try URLRequest.createForJSON(with: url,
                                                       method: method,
                                                       headers: headers,
                                                       queryParams: queryParams,
                                                       body: body,
                                                       encoder: encoder,
                                                       queryStringTypeConverter: queryStringTypeConverter)
            return rxDataRequestDiscardingPayload(request)
        } catch {
            return Single.error(error)
        }
    }
}
