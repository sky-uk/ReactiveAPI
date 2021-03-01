import Foundation
import RxSwift
import Combine

public protocol ReactiveAPIAuthenticator {
    func authenticate(session: Reactive<URLSession>,
                      request: URLRequest,
                      response: HTTPURLResponse,
                      data: Data?) -> Single<Data>?

    func authenticate1(session: URLSession,
                      request: URLRequest,
                      response: HTTPURLResponse,
                      data: Data?) -> AnyPublisher<Data, ReactiveAPIError>?
}
