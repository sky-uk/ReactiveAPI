import Foundation
import RxSwift

extension Reactive where Base: URLSession {
    public func response(_ request: URLRequest, interceptors: [ReactiveAPIRequestInterceptor]? = nil) -> Observable<(request: URLRequest, response: HTTPURLResponse, data: Data)> {
        return Observable.create { observer in
            var mutableRequest = request
            interceptors?.forEach { mutableRequest = $0.intercept(mutableRequest) }

            let task = self.base.dataTask(with: mutableRequest) { data, response, error in
                guard let response = response, let data = data else {
                    observer.on(.error(error ?? ReactiveAPIError.unknown))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    observer.on(.error(ReactiveAPIError.nonHttpResponse(response: response)))
                    return
                }

                if httpResponse.statusCode < 200 || httpResponse.statusCode >= 300 {
                    observer.on(.error(ReactiveAPIError.httpError(request: request, response: httpResponse, data: data)))
                    return
                }

                observer.on(.next((mutableRequest, httpResponse, data)))
                observer.on(.completed)
            }

            task.resume()

            return Disposables.create(with: task.cancel)
        }
    }
}
