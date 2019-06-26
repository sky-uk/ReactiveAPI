import Foundation
import RxSwift

public typealias ReactiveAPITypeConverter = (_ value: Any?) -> String?

public protocol ReactiveAPI {
    var authenticator: ReactiveAPIAuthenticator? { get set }
    var requestInterceptors: [ReactiveAPIRequestInterceptor] { get set }
    var queryStringTypeConverter: ReactiveAPITypeConverter? { get set }
    var cache: ReactiveAPICache? { get set }
    func absoluteURL(_ endpoint: String) -> URL
}
