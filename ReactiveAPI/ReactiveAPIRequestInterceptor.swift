import Foundation

public protocol ReactiveAPIRequestInterceptor {
    func intercept(_ request: URLRequest) -> URLRequest
}
