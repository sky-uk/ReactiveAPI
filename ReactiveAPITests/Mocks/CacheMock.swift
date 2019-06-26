import Foundation
import ReactiveAPI

struct CacheMock: ReactiveAPICache {
    public func cache(_ response: HTTPURLResponse,
                      request: URLRequest,
                      data: Data) -> CachedURLResponse? {
        guard
            let url = response.url,
            let newResponse = HTTPURLResponse(url: url,
                                              statusCode: response.statusCode,
                                              httpVersion: "HTTP/1.1",
                                              headerFields: nil) else { return nil }

        return CachedURLResponse(response: newResponse,
                                 data: data)
    }
}
