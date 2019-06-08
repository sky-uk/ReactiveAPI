import XCTest
import RxSwift
import RxBlocking
import RxCocoa
@testable import ReactiveAPI

class RxDataRequestTests: XCTestCase {
    private let json = """
        [ { "beautiful": "json" } ]
        """

    func test_RxDataRequest_When200_DataIsValid() {
        let session = URLSessionMock.create(json)
        let api = JSONReactiveAPI(session: session.rx,
                                  decoder: JSONDecoder(),
                                  baseUrl: Resources.url)

        do {
            let response = try api.rxDataRequest(URLRequest(url: Resources.url))
                .toBlocking()
                .single()

            XCTAssertNotNil(response)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_RxDataRequest_When500_ReturnError() {
        let session = URLSessionMock.create(json, errorCode: 500)
        
        let api = JSONReactiveAPI(session: session.rx,
                                  decoder: JSONDecoder(),
                                  baseUrl: Resources.url)

        let response = api.rxDataRequest(URLRequest(url: Resources.url))
            .toBlocking()
            .materialize()

        switch response {
        case .completed(elements: _):
            XCTFail("This should throws an error!")
        case .failed(elements: _, error: let error):
            if case let ReactiveAPIError.httpError(response: response, data: _) = error {
                XCTAssertTrue(response.statusCode == 500)
            } else {
                XCTFail("This should be a ReactiveAPIError.httpError")
            }
        }
    }

    func test_RxDataRequest_When401WithAuthenticator_DataIsValid() {
        let session = URLSessionMock.create(json, errorCode: 401)

        let api = JSONReactiveAPI(session: session.rx,
                                  decoder: JSONDecoder(),
                                  baseUrl: Resources.url)
        api.authenticator = AuthenticatorMock(code: 401)

        do {
            let response = try api.rxDataRequest(URLRequest(url: Resources.url))
                .toBlocking()
                .single()

            XCTAssertNotNil(response)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_RxDataRequest_When500WithAuthenticator_ReturnError() {
        let session = URLSessionMock.create(json, errorCode: 500)

        let api = JSONReactiveAPI(session: session.rx,
                                  decoder: JSONDecoder(),
                                  baseUrl: Resources.url)
        api.authenticator = AuthenticatorMock(code: 401)

        let response = api.rxDataRequest(URLRequest(url: Resources.url))
            .toBlocking()
            .materialize()

        switch response {
        case .completed(elements: _):
            XCTFail("This should throws an error!")
        case .failed(elements: _, error: let error):
            if case let ReactiveAPIError.httpError(response: response, data: _) = error {
                XCTAssertTrue(response.statusCode == 500)
            } else {
                XCTFail("This should be a ReactiveAPIError.httpError")
            }
        }
    }

    func test_RxDataRequest_Cache() {
        let session = URLSessionMock.create(json)
        let api = JSONReactiveAPI(session: session.rx,
                                  decoder: JSONDecoder(),
                                  baseUrl: Resources.url)
        let cache = CacheMock()
        api.cache = cache
        let request = URLRequest(url: Resources.url)
        do {
            let _ = try api.rxDataRequest(request)
                .toBlocking()
                .single()

            let urlCache = session.configuration.urlCache
            XCTAssertNotNil(urlCache?.cachedResponse(for: request))

        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
