import Foundation
import ReactiveAPI

struct InterceptorMock: ReactiveAPIRequestInterceptor {
    func intercept(_ request: URLRequest) -> URLRequest {
        var mutableRequest = request
        mutableRequest.addValue("Interceptor", forHTTPHeaderField: UUID().uuidString)
        return mutableRequest
    }
}

public class TokenInterceptor : ReactiveAPIRequestInterceptor {

    private let tokenValue: () -> String
    private let headerName: String

    public init(tokenValue: @escaping () -> String, headerName: String) {
        self.tokenValue = tokenValue
        self.headerName = headerName
    }

    public func intercept(_ request: URLRequest) -> URLRequest {
        var mutableRequest = request
        mutableRequest.addValue(tokenValue(), forHTTPHeaderField: headerName)
        return mutableRequest
    }
}
