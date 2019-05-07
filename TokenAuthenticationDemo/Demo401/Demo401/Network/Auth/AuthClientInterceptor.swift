import Foundation
import ReactiveAPI

class AuthClientInterceptor: ReactiveAPIRequestInterceptor {

    private let tokenStorage: TokenStorage

    init(tokenStorage: TokenStorage) {
        self.tokenStorage = tokenStorage
    }

    func intercept(_ request: URLRequest) -> URLRequest {
        guard let shortLivedToken = self.tokenStorage.token?.shortLivedToken else {
            return request
        }

        debugPrint("interceptor - adding token to request")

        var mutableRequest = request
        mutableRequest.setValue(shortLivedToken, forHTTPHeaderField: "token")
        return mutableRequest
    }
}

