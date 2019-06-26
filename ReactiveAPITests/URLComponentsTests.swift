import XCTest
@testable import ReactiveAPI

class URLComponentsTests: XCTestCase {
    func test_SetQueryParams_WhenDictionaryIsValid_SetQueryItems() {
        var components = URLComponents()
        components.setQueryParams(Resources.params)

        XCTAssert(components.queryItems?.count == 2)
        let first = components.queryItems?.first(where: { $0.name == "key" })
        XCTAssertNotNil(first)
        XCTAssertEqual(first?.value, "value")

        let number = components.queryItems?.first(where: { $0.name == "number" })
        XCTAssertNotNil(number)
        XCTAssertEqual(number?.value, "3")
    }
}
