import Foundation
import ReactiveAPI
import Combine

class MockAPI: ReactiveAPI {

    public static let loginEndpoint = "login"
    public static let renewEndpoint = "renew"
    public static let authenticatedSingleActionEndpoint = "auth-action"
    public static let authenticatedParallelActionEndpoint = "auth-parallel-action"

    func login() -> AnyPublisher<ModelMock, ReactiveAPIError> {
        return request1(url: absoluteURL(MockAPI.loginEndpoint))
    }
    func renewToken() -> AnyPublisher<ModelMock, ReactiveAPIError> {
        return request1(url: absoluteURL(MockAPI.renewEndpoint))
    }

    func authenticatedSingleAction() -> AnyPublisher<ModelMock, ReactiveAPIError> {
        return request1(url: absoluteURL(MockAPI.authenticatedSingleActionEndpoint))
    }

    func authenticatedParallelAction() -> AnyPublisher<ModelMock, ReactiveAPIError> {
        return request1(url: absoluteURL(MockAPI.authenticatedParallelActionEndpoint))
    }
}
