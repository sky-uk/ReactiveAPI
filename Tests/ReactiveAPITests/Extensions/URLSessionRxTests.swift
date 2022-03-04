import XCTest
import ReactiveAPI

class URLSessionRxTests: XCTestCase {
    func test_Fetch_When200_DataIsValid() async {
        let session = URLSessionMock.create(Resources.json)
        do {
            let response = try await session.fetch(Resources.urlRequest)

            XCTAssertNotNil(response)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_Fetch_When500_ReturnError() async {
        let session = URLSessionMock.create(Resources.json, errorCode: 500)
        do {
            let _ = try await session.fetch(Resources.urlRequest)
            XCTFail("This should throws an error!")
        } catch {
            if case let ReactiveAPIError.httpError(request: _, response: response, data: _) = error {
                XCTAssertTrue(response.statusCode == 500)
            } else {
                XCTFail("This should be a ReactiveAPIError.httpError")
            }
        }
    }

    func test_Fetch_When401_ReturnError() async {
        let session = URLSessionMock.create(Resources.json, errorCode: 401)
        do {
            let _ = try await session.fetch(Resources.urlRequest)
            XCTFail("This should throws an error!")
        } catch {
            if case let ReactiveAPIError.httpError(request: _, response: response, data: _) = error {
                XCTAssertTrue(response.statusCode == 401)
            } else {
                XCTFail("This should be a ReactiveAPIError.httpError")
            }
        }
    }

    func test_Fetch_WhenDataNil_UnknownError() async {
        let session = URLSessionMock(response: Resources.httpUrlResponse())
        do {
            let _ = try await session.fetch(Resources.urlRequest)
            XCTFail("This should throws an error!")
        } catch {
            if case ReactiveAPIError.unknown = error {
                XCTAssertNotNil(error)
            } else {
                XCTFail("This should be a ReactiveAPIError.unknown")
            }
        }
    }

    func test_Fetch_WhenResponseNil_UnknownError() async {
        let session = URLSessionMock(data: Resources.json.data(using: .utf8))
        do {
            let _ = try await session.fetch(Resources.urlRequest)
            XCTFail("This should throws an error!")
        } catch {
            if case ReactiveAPIError.unknown = error {
                XCTAssertNotNil(error)
            } else {
                XCTFail("This should be a ReactiveAPIError.unknown")
            }
        }
    }

    func test_Fetch_WhenResponseIsNotHTTP_NonHttpResponse() async {
        let session = URLSessionMock(data: Data(), response: URLResponse())
        do {
            let _ = try await session.fetch(Resources.urlRequest)
            XCTFail("This should throws an error!")
        } catch {
            if case ReactiveAPIError.nonHttpResponse(response: _) = error {
                XCTAssertNotNil(error)
            } else {
                XCTFail("This should be a ReactiveAPIError.nonHttpResponse")
            }
        }
    }

    func test_Fetch_Interceptors() async {
        let intercetors = Array(repeating: InterceptorMock(), count: 6)
        let session = URLSessionMock.create(Resources.json)
        do {
            let response = try await session.fetch(Resources.urlRequest, interceptors: intercetors)

            XCTAssertNotNil(response)
            XCTAssertNotNil(response.request.allHTTPHeaderFields)
            XCTAssertEqual(response.request.allHTTPHeaderFields?.count, intercetors.count)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
