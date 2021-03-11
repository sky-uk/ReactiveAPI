import Foundation
import ReactiveAPI
import RxSwift
import Combine

struct AuthenticatorMock: ReactiveAPIAuthenticator {

    let code: Int

    func authenticate(session: Reactive<URLSession>,
                      request: URLRequest,
                      response: HTTPURLResponse,
                      data: Data?) -> Single<Data>? {
        guard response.statusCode == code
            else { return nil }

        return Single.just(Resources.data)
    }

    func authenticate1(session: URLSession,
                      request: URLRequest,
                      response: HTTPURLResponse,
                      data: Data?) -> AnyPublisher<Data, ReactiveAPIError>? {
        guard response.statusCode == code
        else { return nil }

        return Just(Resources.data)
            .mapError { .generic(error: $0) }
            .eraseToAnyPublisher()
    }
}
