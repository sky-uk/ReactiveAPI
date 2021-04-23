import XCTest
import ReactiveAPI

class URLSessionRxTests: XCTestCase {
    func test_Fetch_When200_DataIsValid() {
        let session = URLSessionMock.create(Resources.json)
        do {
            let response = try session.fetch(Resources.urlRequest)
                .waitForCompletion()
                .first

            XCTAssertNotNil(response)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_Fetch_When500_ReturnError() {
        let session = URLSessionMock.create(Resources.json, errorCode: 500)
        do {
            _ = try await(session.fetch(Resources.urlRequest))

            XCTFail("This should throw an error!")
        } catch {
            if case let ReactiveAPIError.httpError(request: _, response: response, data: _) = error {
                XCTAssertTrue(response.statusCode == 500)
            } else {
                XCTFail("This should be a ReactiveAPIError.httpError")
            }
        }
    }

    func test_Fetch_When401_ReturnError() {
        let session = URLSessionMock.create(Resources.json, errorCode: 401)
        do {
            _ = try await(session.fetch(Resources.urlRequest))

            XCTFail("This should throw an error!")
        } catch {
            if case let ReactiveAPIError.httpError(request: _, response: response, data: _) = error {
                XCTAssertTrue(response.statusCode == 401)
            } else {
                XCTFail("This should be a ReactiveAPIError.httpError")
            }
        }
    }

    func test_Fetch_WhenDataNil_MissingDataError() {
        let session = URLSessionMock(response: Resources.httpUrlResponse())
        do {
            _ = try await(session.fetch(Resources.urlRequest))

            XCTFail("This should throw an error!")
        } catch {
            if case ReactiveAPIError.missingResponseData(request: Resources.urlRequest) = error {
                XCTAssertNotNil(error)
            } else {
                XCTFail("This should be a ReactiveAPIError.missingResponseData(request:)")
            }
        }
    }

    func test_Fetch_WhenResponseNil_MissingResponseError() {
        let session = URLSessionMock(data: Resources.json.data(using: .utf8))
        do {
            _ = try await(session.fetch(Resources.urlRequest))

            XCTFail("This should throw an error!")
        } catch {
            if case ReactiveAPIError.networkError(urlError:) = error { //Questo tipo di errore è diverso da quello sopra, perchè il metodo usato in combine per le chiamate di rete avrà sempre una response
                XCTAssertNotNil(error)
            } else {
                XCTFail("This should be a ReactiveAPIError.networkError(urlError:)")
            }
        }
    }

    func test_Fetch_WhenResponseIsNotHTTP_NonHttpResponse() {
        let session = URLSessionMock(data: Data(), response: URLResponse())
        do {
            _ = try await(session.fetch(Resources.urlRequest))

            XCTFail("This should throw an error!")
        } catch {
            if case ReactiveAPIError.nonHttpResponse(response:) = error {
                XCTAssertNotNil(error)
            } else {
                XCTFail("This should be a ReactiveAPIError.nonHttpResponse")
            }
        }
    }

    func test_Fetch_Interceptors() {
        let intercetors = Array(repeating: InterceptorMock(), count: 6)
        let session = URLSessionMock.create(Resources.json)
        do {
            let response = try session.fetch(Resources.urlRequest, interceptors: intercetors)
                .waitForCompletion()
                .first!

            XCTAssertNotNil(response)
            XCTAssertNotNil(response.request.allHTTPHeaderFields)
            XCTAssertEqual(response.request.allHTTPHeaderFields?.count, intercetors.count)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
