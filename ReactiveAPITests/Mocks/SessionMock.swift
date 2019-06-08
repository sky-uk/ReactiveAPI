import Foundation

class URLSessionMock: URLSession {
    var data: Data?
    var error: Error?
    var response: HTTPURLResponse? = HTTPURLResponse(url: Resources.url,
                                                     statusCode: 200,
                                                     httpVersion: nil,
                                                     headerFields: nil)

    override func dataTask(with request: URLRequest,
                           completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        let data = self.data
        let error = self.error
        let response = self.response
        return URLSessionDataTaskMock {
            completionHandler(data, response, error)
        }
    }
}

extension URLSessionMock {
    static func create(_ json: String) -> URLSession {
        let session = URLSessionMock()
        session.data = json.data(using: .utf8)!
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
