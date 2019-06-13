import XCTest
import RxSwift
@testable import ReactiveAPI

class JSONReactiveAPITests: XCTestCase {
    private let session = URLSession(configuration: URLSessionConfiguration.default)

    private var api: JSONReactiveAPI {
        return JSONReactiveAPI(session: session.rx,
                               decoder: JSONDecoder(),
                               baseUrl: Resources.baseUrl)
    }

    func test_Init_JSONReactiveAPI() {
        XCTAssertEqual(api.session.base, session)
        XCTAssertNotNil(api.decoder)
        XCTAssertTrue(api.decoder is JSONDecoder)
    }

    func test_AbsoluteURL_AppendsEndpoint() {
        let url = api.absoluteURL("path")
        XCTAssertEqual(url.absoluteString, "https://baseurl.com/path")
    }

    func test_AbsoluteURL_AppendsEmptyEndpoint() {
        let url = api.absoluteURL("")
        XCTAssertEqual(url.absoluteString, "https://baseurl.com/")
    }
}
