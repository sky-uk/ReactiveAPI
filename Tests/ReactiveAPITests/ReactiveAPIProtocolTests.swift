import XCTest
@testable import ReactiveAPI

class ReactiveAPIProtocolTests: XCTestCase {

    func test_RxDataRequest_When401WithAuthenticator_DataIsValid() async {
        let session = URLSessionMock.create(Resources.json, errorCode: 401)
        let api = ReactiveAPI(session: session,
                              decoder: JSONDecoder(),
                              baseUrl: Resources.url)
        api.authenticator = AuthenticatorMock(code: 401)

        do {
            let response = try await api.rxDataRequest(Resources.urlRequest)
            
            XCTAssertNotNil(response)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_RxDataRequest_When500WithAuthenticator_ReturnError() async {
        let session = URLSessionMock.create(Resources.json, errorCode: 500)
        let api = ReactiveAPI(session: session,
                              decoder: JSONDecoder(),
                              baseUrl: Resources.url)
        api.authenticator = AuthenticatorMock(code: 401)

        do {
            let _ = try await api.rxDataRequest(Resources.urlRequest)
            XCTFail("This should throws an error!")
        } catch {
            if case let ReactiveAPIError.httpError(request: _, response: response, data: _) = error {
                XCTAssertTrue(response.statusCode == 500)
            } else {
                XCTFail("This should be a ReactiveAPIError.httpError")
            }
        }
    }

    func test_RxDataRequest_Cache() async {
        let session = URLSessionMock.create(Resources.json)
        let api = ReactiveAPI(session: session,
                              decoder: JSONDecoder(),
                              baseUrl: Resources.url)
        let cache = CacheMock()
        api.cache = cache
        let request = Resources.urlRequest
        do {
            _ = try await api.rxDataRequest(request)

            let urlCache = session.configuration.urlCache
            XCTAssertNotNil(urlCache?.cachedResponse(for: request))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_RxDataRequestDecodable_WhenResponseIsValid_ReturnDecoded() async {
        let session = URLSessionMock.create(Resources.jsonResponse)
        let api = ReactiveAPI(session: session,
                              decoder: JSONDecoder(),
                              baseUrl: Resources.url)
        do {
            let response: ModelMock = try await api.rxDataRequest(Resources.urlRequest)

            XCTAssertNotNil(response)
            XCTAssertEqual(response.name, "Patrick")
            XCTAssertEqual(response.id, 5)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_RxDataRequestDecodable_WhenResponseIsInvalid_ReturnError() async {
        let session = URLSessionMock.create(Resources.jsonInvalidResponse)
        let api = ReactiveAPI(session: session,
                              decoder: JSONDecoder(),
                              baseUrl: Resources.url)
        do {
            let _: ModelMock = try await api.rxDataRequest(Resources.urlRequest)
            XCTFail("This should throws an error!")
        } catch {
            if case let ReactiveAPIError.decodingError(_, data: data) = error {
                XCTAssertNotNil(data)
            } else {
                XCTFail("This should be a ReactiveAPIError.decodingError")
            }
        }
    }

    func test_RxDataRequestVoid_WhenResponseIsValid_ReturnDecoded() async {
        let session = URLSessionMock.create(Resources.jsonResponse)
        let api = ReactiveAPI(session: session,
                              decoder: JSONDecoder(),
                              baseUrl: Resources.url)
        do {
            let response: Void = try await api.rxDataRequestDiscardingPayload(Resources.urlRequest)

            XCTAssertNotNil(response)

        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
