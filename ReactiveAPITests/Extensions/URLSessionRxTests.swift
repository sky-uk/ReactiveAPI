import XCTest
import RxSwift
import RxBlocking
import ReactiveAPI

class URLSessionRxTests: XCTestCase {
    func test_Fetch_When200_DataIsValid() {
        let session = URLSessionMock.create(Resources.json)
        do {
            let response = try session.rx.fetch(Resources.urlRequest)
                .toBlocking()
                .single()

            XCTAssertNotNil(response)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_Fetch_When500_ReturnError() {
        let session = URLSessionMock.create(Resources.json, errorCode: 500)
        let response = session.rx.fetch(Resources.urlRequest)
            .toBlocking()
            .materialize()

        switch response {
        case .completed(elements: _):
            XCTFail("This should throws an error!")
        case .failed(elements: _, error: let error):
            if case let ReactiveAPIError.httpError(request: _, response: response, data: _) = error {
                XCTAssertTrue(response.statusCode == 500)
            } else {
                XCTFail("This should be a ReactiveAPIError.httpError")
            }
        }
    }

    func test_Fetch_When401_ReturnError() {
        let session = URLSessionMock.create(Resources.json, errorCode: 401)
        let response = session.rx.fetch(Resources.urlRequest)
            .toBlocking()
            .materialize()

        switch response {
        case .completed(elements: _):
            XCTFail("This should throws an error!")
        case .failed(elements: _, error: let error):
            if case let ReactiveAPIError.httpError(request: _, response: response, data: _) = error {
                XCTAssertTrue(response.statusCode == 401)
            } else {
                XCTFail("This should be a ReactiveAPIError.httpError")
            }
        }
    }

    func test_Fetch_WhenDataNil_UnknownError() {
        let session = URLSessionMock(response: Resources.httpUrlResponse())
        let response = session.rx.fetch(Resources.urlRequest)
            .toBlocking()
            .materialize()

        switch response {
        case .completed(elements: _):
            XCTFail("This should throws an error!")
        case .failed(elements: _, error: let error):
            if case ReactiveAPIError.unknown = error {
                XCTAssertNotNil(error)
            } else {
                XCTFail("This should be a ReactiveAPIError.unknown")
            }
        }
    }

    func test_Fetch_WhenResponseNil_UnknownError() {
        let session = URLSessionMock(data: Resources.json.data(using: .utf8))
        let response = session.rx.fetch(Resources.urlRequest)
            .toBlocking()
            .materialize()

        switch response {
        case .completed(elements: _):
            XCTFail("This should throws an error!")
        case .failed(elements: _, error: let error):
            if case ReactiveAPIError.unknown = error {
                XCTAssertNotNil(error)
            } else {
                XCTFail("This should be a ReactiveAPIError.unknown")
            }
        }
    }
}
