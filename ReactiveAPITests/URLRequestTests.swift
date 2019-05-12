import XCTest
import ReactiveAPI

class URLRequestTests: XCTestCase {
    func test_SetHeaders_WhenDictionaryIsValid_SetHTTPHeaderField() {
        var request = URLRequest(url: URL(string: "www")!)
        request.setHeaders(["key":"value",
                            "number": 3])
        XCTAssertEqual(request.allHTTPHeaderFields, ["key":"value", "number": "3"])
    }
}
