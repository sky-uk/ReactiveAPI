import Foundation
import RxSwift
import ReactiveAPI

class MockAPI: ReactiveAPI {

    public static let loginEndpoint = "login"
    public static let renewEndpoint = "renew"
    public static let authenticatedSingleActionEndpoint = "auth-action"
    public static let authenticatedParallelActionEndpoint = "auth-parallel-action"

    func login() -> Single<ModelMock> {
        return request(url: absoluteURL(MockAPI.loginEndpoint))
    }

    func renewToken() -> Single<ModelMock> {
        return request(url: absoluteURL(MockAPI.renewEndpoint))
    }

    func authenticatedSingleAction() -> Single<ModelMock> {
        return request(url: absoluteURL(MockAPI.authenticatedSingleActionEndpoint))
    }

    func authenticatedParallelAction() -> Single<ModelMock> {
        return request(url: absoluteURL(MockAPI.authenticatedParallelActionEndpoint))
    }
}
