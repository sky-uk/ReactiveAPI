import Foundation
import ReactiveAPI
import RxSwift

struct AuthenticatorMock: ReactiveAPIAuthenticator {
    let code: Int

    func authenticate(session: Reactive<URLSession>, request: URLRequest, response: HTTPURLResponse, data: Data?) -> Single<Data>? {
        guard response.statusCode == code
            else { return nil }

        return Single.just(Data(count: 10))
    }
}
