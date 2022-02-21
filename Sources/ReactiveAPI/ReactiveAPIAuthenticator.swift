import Foundation

public protocol ReactiveAPIAuthenticator {
    func authenticate(session: URLSession,
                      request: URLRequest,
                      response: HTTPURLResponse,
                      data: Data?) async throws -> Data?
}
