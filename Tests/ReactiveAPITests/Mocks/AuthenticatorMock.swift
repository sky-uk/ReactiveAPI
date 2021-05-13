import Foundation
import ReactiveAPI
import Combine

struct AuthenticatorMock: ReactiveAPIAuthenticator {

    let code: Int

    func authenticate(session: URLSession,
                      request: URLRequest,
                      response: HTTPURLResponse,
                      data: Data?) -> AnyPublisher<Data, ReactiveAPIError>? {
        guard response.statusCode == code
        else { return nil }

        return Just(Resources.data)
            .setFailureType(to: ReactiveAPIError.self)
            .eraseToAnyPublisher()
    }
}
