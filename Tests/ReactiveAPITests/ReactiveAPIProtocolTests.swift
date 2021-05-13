import XCTest
@testable import ReactiveAPI

class ReactiveAPIProtocolTests: XCTestCase {

    func test_ReactiveDataRequest_When401WithAuthenticator_DataIsValid() {
        let session = URLSessionMock.create(Resources.json, errorCode: 401)
        let api = ReactiveAPI(session: session,
                              decoder: JSONDecoder(),
                              baseUrl: Resources.url)
        api.authenticator = AuthenticatorMock(code: 401)

        do {
            let response = try api.reactiveDataRequest(Resources.urlRequest)
                .waitForCompletion()
                .first

            XCTAssertNotNil(response)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_ReactiveDataRequest_When500WithAuthenticator_ReturnError() {
        let session = URLSessionMock.create(Resources.json, errorCode: 500)
        let api = ReactiveAPI(session: session,
                              decoder: JSONDecoder(),
                              baseUrl: Resources.url)
        api.authenticator = AuthenticatorMock(code: 401)

        do {
            _ = try awaitCompletion(api.reactiveDataRequest(Resources.urlRequest))

            XCTFail("This should throw an error!")
        } catch {
            if case let ReactiveAPIError.httpError(request: _, response: response, data: _) = error {
                XCTAssertTrue(response.statusCode == 500)
            } else {
                XCTFail("This should be a ReactiveAPIError.httpError")
            }
        }
    }

    func test_ReactiveDataRequest_Cache() {
        let session = URLSessionMock.create(Resources.json)
        let api = ReactiveAPI(session: session,
                              decoder: JSONDecoder(),
                              baseUrl: Resources.url)
        let cache = CacheMock()
        api.cache = cache
        let request = Resources.urlRequest
        do {
            _ = try awaitCompletion(api.reactiveDataRequest(request))

            let urlCache = session.configuration.urlCache
            XCTAssertNotNil(urlCache?.cachedResponse(for: request))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_ReactiveDataRequestDecodable_WhenResponseIsValid_ReturnDecoded() {
        let session = URLSessionMock.create(Resources.jsonResponse)
        let api = ReactiveAPI(session: session,
                              decoder: JSONDecoder(),
                              baseUrl: Resources.url)
        do {
            let response: ModelMock = try api.reactiveDataRequest(Resources.urlRequest)
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

    func test_ReactiveDataRequestDecodable_WhenResponseIsInvalid_ReturnError() {
        let session = URLSessionMock.create(Resources.jsonInvalidResponse)
        let api = ReactiveAPI(session: session,
                              decoder: JSONDecoder(),
                              baseUrl: Resources.url)
        do {
            let _: ModelMock = try awaitCompletion(api.reactiveDataRequest(Resources.urlRequest))
            XCTFail("This should throw an error!")
        } catch {
            if case let ReactiveAPIError.decodingError(underlyingError: underlyingError) = error {
                XCTAssertNotNil(underlyingError)
            } else {
                XCTFail("This should be a ReactiveAPIError.decodingError")
            }
        }
    }

    func test_ReactiveDataRequestVoid_WhenResponseIsValid_ReturnDecoded() {
        let session = URLSessionMock.create(Resources.jsonResponse)
        let api = ReactiveAPI(session: session,
                              decoder: JSONDecoder(),
                              baseUrl: Resources.url)
        do {
            let response: Void? = try api.reactiveDataRequestDiscardingPayload(Resources.urlRequest)
                .waitForCompletion()
                .first

            XCTAssertNotNil(response)

        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
