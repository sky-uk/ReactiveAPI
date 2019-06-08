import XCTest
import ReactiveAPI

class MaxAgeCacheTests: XCTestCase {
    private let cache = MaxAgeCache(maxAge: 2)
    private let response = Resources.httpUrlResponse()
    private var request = Resources.urlRequest
    private let data = Resources.data

    func test_Init_MaxAgeCache() {
        XCTAssertNotNil(cache)
    }

    func test_Cache_WhenParamsAreValid_ReturnCachedResponse() {
        request.setValue("value", forHTTPHeaderField: "Expires")

        let cachedResponse = cache.cache(response!, request: request, data: data)

        XCTAssertNotNil(cachedResponse)
        XCTAssertEqual(cachedResponse?.response.url, response?.url)
        XCTAssertEqual((cachedResponse?.response as! HTTPURLResponse).statusCode, response?.statusCode)
        XCTAssertEqual((cachedResponse?.response as! HTTPURLResponse).allHeaderFields["Cache-Control"] as! String, "public, max-age=2")
        XCTAssertNil((cachedResponse?.response as! HTTPURLResponse).allHeaderFields["Expires"])
    }

    func test_Cache_WhenMethodIsInvalid_ReturnNil() {
        request.httpMethod = "POST"
        let cachedResponse = cache.cache(response!, request: request, data: data)
        XCTAssertNil(cachedResponse)
    }
}
