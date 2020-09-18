import Foundation
import RxSwift

public protocol ReactiveAPIAuthenticator {
    func authenticate(session: Reactive<URLSession>,
                      request: URLRequest,
                      response: HTTPURLResponse,
                      data: Data?) -> Single<Data>?
}
