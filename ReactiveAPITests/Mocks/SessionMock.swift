import Foundation

class URLSessionMock: URLSession {
    var data: Data?
    var error: Error?
    var response: HTTPURLResponse?
    private let configurationMock = URLSessionConfigurationMock()

    override func dataTask(with request: URLRequest,
                           completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        let data = self.data
        let error = self.error
        let response = self.response
        return URLSessionDataTaskMock {
            completionHandler(data, response, error)
        }
    }

    override var configuration: URLSessionConfiguration {
        return configurationMock
    }
}

extension URLSessionMock {
    static func create(_ json: String, errorCode: Int = 200) -> URLSession {
        let session = URLSessionMock()
        session.data = json.data(using: .utf8)!
        session.response = Resources.httpUrlResponse(code: errorCode)
        return session
    }
}

class URLSessionDataTaskMock: URLSessionDataTask {
    private let closure: () -> Void

    init(closure: @escaping () -> Void) {
        self.closure = closure
    }

    override func resume() {
        closure()
    }

    override func cancel() {}
}


class URLSessionConfigurationMock: URLSessionConfiguration {
    private var cache: URLCache? = URLCache(memoryCapacity: 5 * 1024 * 1024,
                                            diskCapacity: 5 * 1024 * 1024,
                                            diskPath: "test")
    override var urlCache: URLCache? {
        get {
            return cache
        }
        set {
            self.cache = newValue
        }
    }
}
