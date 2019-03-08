import Foundation
import RxSwift

public protocol ReactiveAPI {
    var authenticator: ReactiveAPIAuthenticator? { get set }
    var requestInterceptors: [ReactiveAPIRequestInterceptor] { get set }
    var cache: ReactiveAPICache? { get set }
    init(session: Reactive<URLSession>, decoder: ReactiveAPIDecoder, baseUrl: URL)
    func absoluteURL(_ endpoint: String) -> URL
}
