import XCTest
import ReactiveAPI

class URLRequestTests: XCTestCase {
    private let params: [String : Any?] = ["key": "value",
                                           "number": 3,
                                           "nil": nil]

    func test_SetHeaders_WhenDictionaryIsValid_SetHTTPHeaderField() {
        var request = URLRequest(url: URL(string: "www")!)
        request.setHeaders(params)
        XCTAssert(request.allHTTPHeaderFields?.count == 2)
        XCTAssertEqual(request.allHTTPHeaderFields, ["key":"value",
                                                     "number": "3"])
    }

    func test_SetQueryParams_WhenDictionaryIsValid_SetQueryItems() {
        var components = URLComponents()
        components.setQueryParams(params)

        XCTAssert(components.queryItems?.count == 2)
        let first = components.queryItems?.first(where: { $0.name == "key" })
        XCTAssertNotNil(first)
        XCTAssertEqual(first?.value, "value")

        let number = components.queryItems?.first(where: { $0.name == "number" })
        XCTAssertNotNil(number)
        XCTAssertEqual(number?.value, "3")
    }
}
