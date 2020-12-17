import Foundation

public protocol ReactiveAPICache {
    func cache(_ response: HTTPURLResponse,
               request: URLRequest,
               data: Data) -> CachedURLResponse?
}
