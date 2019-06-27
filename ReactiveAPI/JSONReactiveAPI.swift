import Foundation
import RxSwift
import RxCocoa

open class JSONReactiveAPI: ReactiveAPI {
    let session: Reactive<URLSession>
    let decoder: JSONDecoder
    let encoder: JSONEncoder
    private let baseUrl: URL
    public var authenticator: ReactiveAPIAuthenticator?
    public var requestInterceptors: [ReactiveAPIRequestInterceptor] = []
    public var cache: ReactiveAPICache?
    public var queryStringTypeConverter: ReactiveAPITypeConverter?

    public init(session: Reactive<URLSession>,
                decoder: JSONDecoder = JSONDecoder(),
                encoder: JSONEncoder = JSONEncoder(),
                baseUrl: URL) {
        self.session = session
        self.decoder = decoder
        self.encoder = encoder
        self.baseUrl = baseUrl
    }

    public func absoluteURL(_ endpoint: String) -> URL {
        return baseUrl.appendingPathComponent(endpoint)
    }

    // every request must pass here
    func rxDataRequest(_ request: URLRequest) -> Single<Data> {

        var mutableRequest = request

        requestInterceptors.forEach { mutableRequest = $0.intercept(mutableRequest) }

        return session.response(request: mutableRequest)
            .flatMap { response, data -> Observable<Data>  in
                if response.statusCode < 200 || response.statusCode >= 300 {
                    return Observable.error(ReactiveAPIError.httpError(response: response, data: data))
                }

                if
                    let cache = self.cache,
                    let urlCache = self.session.base.configuration.urlCache,
                    let cachedResponse = cache.cache(response,
                                                     request: mutableRequest,
                                                     data: data) {
                    urlCache.storeCachedResponse(cachedResponse,
                                                 for: mutableRequest)
                }

                return Observable.just(data)
            }
            .asSingle()
            .catchError { error -> Single<Data> in
                guard
                    let authenticator = self.authenticator,
                    case let ReactiveAPIError.httpError(response, data) = error,
                    let retryRequest = authenticator.authenticate(session: self.session,
                                                                  request: mutableRequest,
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

    // body params as dictionary and generic response type
    public func request<D: Decodable>(_ method: ReactiveAPIHTTPMethod = .get,
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
    public func request<E: Encodable, D: Decodable>(_ method: ReactiveAPIHTTPMethod = .get,
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
    public func request(_ method: ReactiveAPIHTTPMethod = .get,
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
    public func request<E: Encodable>(_ method: ReactiveAPIHTTPMethod = .get,
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
