import Foundation
import RxSwift

public class AuthClient: AuthAPI {

    public var tokenStorage: TokenStorage!

    public override func login(username: String, password: String) -> Single<TokenPair> {
        return super.login(username: username, password: password)
            .do(onSuccess: { [unowned self] tokenPair in
                self.tokenStorage.token = tokenPair
            })
    }

    public func renewToken() -> Single<TokenPair> {
        return super.renewToken(tokenPair: tokenStorage.token)
            .do(onSuccess: { [unowned self] tokenPair in
                self.tokenStorage.token = tokenPair
            })
    }
}

