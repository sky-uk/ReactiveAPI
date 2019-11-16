import Foundation
import ReactiveAPI

struct InterceptorMock: ReactiveAPIRequestInterceptor {
    func intercept(_ request: URLRequest) -> URLRequest {
        var mutableRequest = request
        mutableRequest.addValue("Interceptor", forHTTPHeaderField: UUID().uuidString)
        return mutableRequest
    }
}
