import XCTest
@testable import ReactiveAPI

class JSONReactiveAPITests: XCTestCase {
    private let session = URLSession(configuration: URLSessionConfiguration.default)

    private var api: ReactiveAPI {
        return ReactiveAPI(session: session,
                           baseUrl: Resources.baseUrl)
    }

    func test_Init_JSONReactiveAPI() {
        XCTAssertEqual(api.session, session)
        XCTAssertNotNil(api.decoder)
    }

    func test_AbsoluteURL_AppendsEndpoint() {
        let url = api.absoluteURL("path")
        XCTAssertEqual(url.absoluteString, "http://localhost:8080/path")
    }

    func test_AbsoluteURL_AppendsEmptyEndpoint() {
        let url = api.absoluteURL("")
        XCTAssertEqual(url.absoluteString, "http://localhost:8080/")
    }
}
