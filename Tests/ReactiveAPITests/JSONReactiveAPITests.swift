import XCTest
import RxSwift
@testable import ReactiveAPI

class JSONReactiveAPITests: XCTestCase {
    private let session = URLSession(configuration: URLSessionConfiguration.default)

    private var api: ReactiveAPI {
        return ReactiveAPI(session: session.rx,
                           baseUrl: Resources.baseUrl)
    }

    private var api1: ReactiveAPI {
        return ReactiveAPI(session: session,
                           baseUrl: Resources.baseUrl)
    }

    func test_Init_JSONReactiveAPI() {
        XCTAssertEqual(api.session.base, session)
        XCTAssertNotNil(api.decoder)
    }

    func test_Init_JSONReactiveAPI_Combine() {
        XCTAssertEqual(api1.session1, session)
        XCTAssertNotNil(api1.decoder)
    }

    func test_AbsoluteURL_AppendsEndpoint() {
        let url = api.absoluteURL("path")
        XCTAssertEqual(url.absoluteString, "http://www.mock.com/path")
    }

    func test_AbsoluteURL_AppendsEndpoint_Combine() {
        let url = api1.absoluteURL("path")
        XCTAssertEqual(url.absoluteString, "http://www.mock.com/path")
    }

    func test_AbsoluteURL_AppendsEmptyEndpoint() {
        let url = api.absoluteURL("")
        XCTAssertEqual(url.absoluteString, "http://www.mock.com/")
    }

    func test_AbsoluteURL_AppendsEmptyEndpoint_Combine() {
        let url = api1.absoluteURL("")
        XCTAssertEqual(url.absoluteString, "http://www.mock.com/")
    }
}
