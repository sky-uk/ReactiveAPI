import XCTest
import RxSwift
import RxBlocking
@testable import ReactiveAPI

class ReactiveAPIProtocolTests: XCTestCase {

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

    func test_RxDataRequest_When401WithAuthenticator_DataIsValid_Combine() {
        let session = URLSessionMock.create(Resources.json, errorCode: 401)
        let api = ReactiveAPI(session: session,
                              decoder: JSONDecoder(),
                              baseUrl: Resources.url)
        api.authenticator = AuthenticatorMock(code: 401)

        do {
            let response = try api.rxDataRequest1(Resources.urlRequest)
                .waitForCompletion()
                .first

            XCTAssertNotNil(response)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_RxDataRequest_When401WithAuthenticator_DataIsValid_Comparison() {
        let session = URLSessionMock.create(Resources.json, errorCode: 401)
        let api1 = ReactiveAPI(session: session.rx,
                              decoder: JSONDecoder(),
                              baseUrl: Resources.url)
        api1.authenticator = AuthenticatorMock(code: 401)

        let api2 = ReactiveAPI(session: session,
                              decoder: JSONDecoder(),
                              baseUrl: Resources.url)
        api2.authenticator = AuthenticatorMock(code: 401)

        do {
            let response1 = try api1.rxDataRequest(Resources.urlRequest)
                .toBlocking()
                .single()

            let response2 = try api2.rxDataRequest1(Resources.urlRequest)
                .waitForCompletion()
                .first

            XCTAssertNotNil(response1)
            XCTAssertNotNil(response2)
            XCTAssertEqual(response1, response2)
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
            XCTFail("This should throw an error!")
        case .failed(elements: _, error: let error):
            if case let ReactiveAPIError.httpError(request: _, response: response, data: _) = error {
                XCTAssertTrue(response.statusCode == 500)
            } else {
                XCTFail("This should be a ReactiveAPIError.httpError")
            }
        }
    }

    func test_RxDataRequest_When500WithAuthenticator_ReturnError_Combine() {
        let session = URLSessionMock.create(Resources.json, errorCode: 500)
        let api = ReactiveAPI(session: session,
                              decoder: JSONDecoder(),
                              baseUrl: Resources.url)
        api.authenticator = AuthenticatorMock(code: 401)

        do {
            _ = try await(api.rxDataRequest1(Resources.urlRequest))

            XCTFail("This should throw an error!")
        } catch {
            if case let ReactiveAPIError.httpError(request: _, response: response, data: _) = error {
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

    func test_RxDataRequest_Cache_Combine() {
        let session = URLSessionMock.create(Resources.json)
        let api = ReactiveAPI(session: session,
                              decoder: JSONDecoder(),
                              baseUrl: Resources.url)
        let cache = CacheMock()
        api.cache = cache
        let request = Resources.urlRequest
        do {
            _ = try await(api.rxDataRequest1(request))

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

    func test_RxDataRequestDecodable_WhenResponseIsValid_ReturnDecoded_Combine() {
        let session = URLSessionMock.create(Resources.jsonResponse)
        let api = ReactiveAPI(session: session,
                              decoder: JSONDecoder(),
                              baseUrl: Resources.url)
        do {
            let response: ModelMock = try api.rxDataRequest1(Resources.urlRequest)
                .waitForCompletion()
                .first
                .map { $0 as ModelMock }!

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
            XCTFail("This should throw an error!")
        case .failed(elements: _, error: let error):
            if case let ReactiveAPIError.decodingError(_, data: data) = error {
                XCTAssertNotNil(data)
            } else {
                XCTFail("This should be a ReactiveAPIError.decodingError")
            }
        }
    }

    func test_RxDataRequestDecodable_WhenResponseIsInvalid_ReturnError_Combine() {
        let session = URLSessionMock.create(Resources.jsonInvalidResponse)
        let api = ReactiveAPI(session: session,
                              decoder: JSONDecoder(),
                              baseUrl: Resources.url)
        do {
            let _: ModelMock = try await(api.rxDataRequest1(Resources.urlRequest))
            XCTFail("This should throw an error!")
        } catch {
            if case let ReactiveAPIError.decodingError1(underlyingError: underlyingError) = error {
                XCTAssertNotNil(underlyingError)
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

    func test_RxDataRequestVoid_WhenResponseIsValid_ReturnDecoded_Combine() {
        let session = URLSessionMock.create(Resources.jsonResponse)
        let api = ReactiveAPI(session: session,
                              decoder: JSONDecoder(),
                              baseUrl: Resources.url)
        do {
            let response: Void = try api.rxDataRequestDiscardingPayload1(Resources.urlRequest)
                .waitForCompletion()
                .first!

            XCTAssertNotNil(response)

        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
