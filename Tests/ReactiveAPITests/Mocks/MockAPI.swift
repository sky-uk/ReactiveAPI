import Foundation
import ReactiveAPI

class MockAPI: ReactiveAPI {

    public static let loginEndpoint = "login"
    public static let renewEndpoint = "renew"
    public static let authenticatedSingleActionEndpoint = "auth-action"
    public static let authenticatedParallelActionEndpoint = "auth-parallel-action"

    func login() async throws -> ModelMock {
        return try await request(url: absoluteURL(MockAPI.loginEndpoint))
    }

    func renewToken() async throws -> ModelMock {
        return try await request(url: absoluteURL(MockAPI.renewEndpoint))
    }

    func authenticatedSingleAction() async throws -> ModelMock {
        return try await request(url: absoluteURL(MockAPI.authenticatedSingleActionEndpoint))
    }

    func authenticatedParallelAction() async throws -> ModelMock {
        return try await request(url: absoluteURL(MockAPI.authenticatedParallelActionEndpoint))
    }
}
