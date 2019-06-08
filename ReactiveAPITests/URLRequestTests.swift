import XCTest
import ReactiveAPI

class URLRequestTests: XCTestCase {
    private let params: [String : Any?] = ["key": "value",
                                           "number": 3,
                                           "nil": nil]

    func test_SetHeaders_WhenDictionaryIsValid_SetHTTPHeaderField() {
        var request = Resources.urlRequest
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

    func test_createForJSON_WhenGetParamsAreValid_ReturnRequest() {
        do {
            let request = try URLRequest.createForJSON(with: Resources.url,
                                                       method: .get,
                                                       headers: params,
                                                       queryParams: params,
                                                       bodyParams: params,
                                                       queryStringTypeConverter: nil)
            XCTAssertNotNil(request)
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.allHTTPHeaderFields, ["key":"value",
                                                         "number": "3",
                                                         "Accept": "application/json"])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_createForJSON_WhenPatchParamsAreValid_ReturnRequest() {
        do {
            let request = try URLRequest.createForJSON(with: Resources.url,
                                                       method: .patch,
                                                       headers: params,
                                                       queryParams: params,
                                                       bodyParams: params,
                                                       queryStringTypeConverter: nil)
            XCTAssertNotNil(request)
            XCTAssertEqual(request.httpMethod, "PATCH")
            XCTAssertEqual(request.allHTTPHeaderFields, ["Accept": "application/json",
                                                         "number": "3",
                                                         "Content-Type": "application/json",
                                                         "key": "value"])

            let bodyDict = try JSONSerialization.jsonObject(with: request.httpBody!, options: []) as? [String: Any]
            XCTAssert(bodyDict!.count == 2)
            XCTAssertEqual(bodyDict!["number"] as! Int, 3)
            XCTAssertEqual(bodyDict!["key"] as! String, "value")

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_createForJSON_WhenPutParamsAreValid_ReturnRequest() {
        do {
            let body = ModelMock(name: "Elisa", id: 123)
            let request = try URLRequest.createForJSON(with: Resources.url,
                                                       method: .put,
                                                       body: body,
                                                       queryStringTypeConverter: nil)
            XCTAssertNotNil(request)

            let bodyDict = try JSONSerialization.jsonObject(with: request.httpBody!, options: []) as? [String: Any]
            XCTAssert(bodyDict!.count == 2)
            XCTAssertEqual(bodyDict!["id"] as! Double, 123)
            XCTAssertEqual(bodyDict!["name"] as! String, "Elisa")

        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
