import Swifter
import Foundation
import XCTest

class SkyTestCase: XCTestCase {

    var httpServer: HttpServer = HttpServer()

    override func setUp() {
        super.setUp()
        httpServer.stop()
    }

    override func tearDown() {
        httpServer.stop()
        super.tearDown()
    }

    func startServer() throws {
        try httpServer.start(8080)
    }
}

extension HttpServer {
    func route(_ endpoint: String, _ completion: @escaping (HttpRequest, Int) -> (HttpResponse)) {
        let lock = DispatchSemaphore(value: 1)
        var callCount = 0
        self[endpoint] = { request in
            lock.wait()
            callCount += 1
            lock.signal()
            return completion(request, callCount)
        }

    }
}

extension HttpResponse {
    static func ok(_ data: Data) -> HttpResponse {
        return HttpResponse.ok(HttpResponseBody.data(data))
    }
}


extension HttpRequest {

    func header(name: String) -> String? {
        return self.headers[name]
    }

    func queryParam(name: String) -> String? {
        return self.queryParams.first { (tupla) -> Bool in
            return tupla.0 == name
            }?.1
    }
}

