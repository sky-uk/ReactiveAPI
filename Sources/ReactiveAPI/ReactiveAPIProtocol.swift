import Foundation
import RxSwift

public typealias ReactiveAPITypeConverter = (_ value: Any?) -> String?

public protocol ReactiveAPIProtocol {
    var baseUrl: URL { get }
    var session: Reactive<URLSession> { get }
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
            .catch { error -> Single<Data> in
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

    func rxDataRequestDiscardingPayload(_ request: URLRequest) -> Single<Void> {
        return rxDataRequest(request).map { _ in () }
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
