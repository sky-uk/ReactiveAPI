import Foundation
import Combine

public protocol ReactiveAPIAuthenticator {
    func authenticate(session: URLSession,
                      request: URLRequest,
                      response: HTTPURLResponse,
                      data: Data?) -> AnyPublisher<Data, ReactiveAPIError>?
}
