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
}
