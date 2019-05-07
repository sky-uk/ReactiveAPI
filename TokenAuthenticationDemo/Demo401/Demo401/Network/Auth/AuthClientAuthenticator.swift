import Foundation
import ReactiveAPI
import RxSwift

public class AuthClientAuthenticator: ReactiveAPIAuthenticator {

    private let authClient: AuthClient

    public init(authClient: AuthClient) {
        self.authClient = authClient
    }

    public func authenticate(session: Reactive<URLSession>, request: URLRequest, response: HTTPURLResponse, data: Data?) -> Single<Data>? {
        debugPrint("Invoked authenticator")
        guard response.statusCode == 401, let token = self.authClient.tokenStorage?.token else {
            debugPrint(response.statusCode == 401 ? "authenticator - no saved tokens" : "authenticator - response status code != 401")
            return nil
        }

        debugPrint("authenticator - trying to refresh token: \(token)")

        return self.authClient.renewToken()
            .flatMap { newToken in
                debugPrint("authenticator - got new token: \(newToken)")
                var newRequest = request
                newRequest.setValue(newToken.shortLivedToken, forHTTPHeaderField: "token")
                return session.data(request: newRequest).asSingle()
        }
    }

}

