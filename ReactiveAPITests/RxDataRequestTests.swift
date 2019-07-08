import XCTest
import RxSwift
import RxBlocking
@testable import ReactiveAPI

class RxDataRequestTests: XCTestCase {
    func test_RxDataRequest_When200_DataIsValid() {
        let session = URLSessionMock.create(Resources.json)
        let api = ReactiveAPI(session: session.rx,
                                  decoder: JSONDecoder(),
                                  baseUrl: Resources.url)
        do {
            let response = try api.rxDataRequest(Resources.urlRequest)
                .toBlocking()
                .single()

            XCTAssertNotNil(response)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_RxDataRequest_When500_ReturnError() {
        let session = URLSessionMock.create(Resources.json, errorCode: 500)
        let api = ReactiveAPI(session: session.rx,
                                  decoder: JSONDecoder(),
                                  baseUrl: Resources.url)
        let response = api.rxDataRequest(Resources.urlRequest)
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
        let session = URLSessionMock.create(Resources.json, errorCode: 401)
        let api = ReactiveAPI(session: session.rx,
                                  decoder: JSONDecoder(),
                                  baseUrl: Resources.url)
        api.authenticator = AuthenticatorMock(code: 401)

        do {
            let response = try api.rxDataRequest(Resources.urlRequest)
                .toBlocking()
                .single()

            XCTAssertNotNil(response)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_RxDataRequest_When500WithAuthenticator_ReturnError() {
        let session = URLSessionMock.create(Resources.json, errorCode: 500)
        let api = ReactiveAPI(session: session.rx,
                                  decoder: JSONDecoder(),
                                  baseUrl: Resources.url)
        api.authenticator = AuthenticatorMock(code: 401)

        let response = api.rxDataRequest(Resources.urlRequest)
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
        let session = URLSessionMock.create(Resources.json)
        let api = ReactiveAPI(session: session.rx,
                                  decoder: JSONDecoder(),
                                  baseUrl: Resources.url)
        let cache = CacheMock()
        api.cache = cache
        let request = Resources.urlRequest
        do {
            _ = try api.rxDataRequest(request)
                .toBlocking()
                .single()

            let urlCache = session.configuration.urlCache
            XCTAssertNotNil(urlCache?.cachedResponse(for: request))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_RxDataRequestDecodable_WhenResponseIsValid_ReturnDecoded() {
        let session = URLSessionMock.create(Resources.jsonResponse)
        let api = ReactiveAPI(session: session.rx,
                                  decoder: JSONDecoder(),
                                  baseUrl: Resources.url)
        do {
            let response: ModelMock = try api.rxDataRequest(Resources.urlRequest)
                .toBlocking()
                .single()

            XCTAssertNotNil(response)
            XCTAssertEqual(response.name, "Patrick")
            XCTAssertEqual(response.id, 5)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_RxDataRequestDecodable_WhenResponseIsInvalid_ReturnError() {
        let session = URLSessionMock.create(Resources.jsonInvalidResponse)
        let api = ReactiveAPI(session: session.rx,
                                  decoder: JSONDecoder(),
                                  baseUrl: Resources.url)
        let response: MaterializedSequenceResult<ModelMock> = api.rxDataRequest(Resources.urlRequest)
            .toBlocking()
            .materialize()

        switch response {
        case .completed(elements: _):
            XCTFail("This should throws an error!")
        case .failed(elements: _, error: let error):
            if case let ReactiveAPIError.decodingError(_, data: data) = error {
                XCTAssertNotNil(data)
            } else {
                XCTFail("This should be a ReactiveAPIError.decodingError")
            }
        }
    }

    func test_RxDataRequestVoid_WhenResponseIsValid_ReturnDecoded() {
        let session = URLSessionMock.create(Resources.jsonResponse)
        let api = ReactiveAPI(session: session.rx,
                                  decoder: JSONDecoder(),
                                  baseUrl: Resources.url)
        do {
            let response: Void = try api.rxDataRequestDiscardingPayload(Resources.urlRequest)
                .toBlocking()
                .single()

            XCTAssertNotNil(response)

        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
