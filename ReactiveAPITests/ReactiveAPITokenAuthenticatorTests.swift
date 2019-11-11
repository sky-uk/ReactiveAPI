import XCTest
import RxSwift
@testable import ReactiveAPI

class ReactiveAPITokenAuthenticatorTests: XCTestCase {
    private let authenticator = ReactiveAPITokenAuthenticator(tokenHeaderName: "tokenHeaderName",
                                                              getCurrentToken: { "getCurrentToken" },
                                                              renewToken: { Single.just("renewToken") })

    func test_requestWithNewToken_When200_DataIsValid() {
        let session = URLSessionMock.create(Resources.json)
        do {
            let response = try authenticator.requestWithNewToken(session: session.rx,
                                                                 request: Resources.urlRequest,
                                                                 newToken: "newToken")
                .toBlocking()
                .single()

            XCTAssertNotNil(response)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_requestWithNewToken_When500_ReturnError() {
        let session = URLSessionMock.create(Resources.json, errorCode: 500)
        let response = authenticator.requestWithNewToken(session: session.rx,
                                                         request: Resources.urlRequest,
                                                         newToken: "newToken")
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
        let response = authenticator.requestWithNewToken(session: session.rx,
                                                         request: Resources.urlRequest,
                                                         newToken: "newToken")
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

    func test_Authenticate_When401_Nil() {
        let session = URLSessionMock.create(Resources.json)
        let authenticator = ReactiveAPITokenAuthenticator(tokenHeaderName: "tokenHeaderName",
                                                          getCurrentToken: { nil },
                                                          renewToken: { Single.just("renewToken") })
        do {
            let response = try authenticator.authenticate(session: session.rx,
                                                          request: Resources.urlRequest,
                                                          response: Resources.httpUrlResponse(code: 401)!,
                                                          data: nil)?
                .toBlocking()
                .single()

            XCTAssertNil(response)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_Authenticate_WhenGetCurrentTokenNil_Nil() {
        let session = URLSessionMock.create(Resources.json)
        do {
            let response = try authenticator.authenticate(session: session.rx,
                                                          request: Resources.urlRequest,
                                                          response: Resources.httpUrlResponse(code: 500)!,
                                                          data: nil)?
                .toBlocking()
                .single()

            XCTAssertNil(response)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_Authenticate_WhenIsRenewingTokenTrue_RequestWithNewToken() {
        let session = URLSessionMock.create(Resources.json)
        authenticator.setNewToken(token: "token", isRenewing: true)
        do {
            let response = try authenticator.authenticate(session: session.rx,
                                                          request: Resources.urlRequest,
                                                          response: Resources.httpUrlResponse(code: 401)!,
                                                          data: nil)?
                .toBlocking()
                .single()

            XCTAssertNotNil(response)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_Authenticate_RenewToken() {
        let session = URLSessionMock.create(Resources.json)
        do {
            let response = try authenticator.authenticate(session: session.rx,
                                                          request: Resources.urlRequest,
                                                          response: Resources.httpUrlResponse(code: 401)!,
                                                          data: nil)?
                .toBlocking()
                .single()

            XCTAssertNotNil(response)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }


    func test_Authenticate_RenewToken_TokenRenewError() {
        let session = URLSessionMock.create(Resources.json, errorCode: 500)
        let response = authenticator.authenticate(session: session.rx,
                                                  request: Resources.urlRequest,
                                                  response: Resources.httpUrlResponse(code: 401)!,
                                                  data: nil)?
            .toBlocking()
            .materialize()

        switch response {
            case .failed(elements: _, error: let error):
                if case let ReactiveAPIError.httpError(request: _, response: response, data: _) = error {
                    XCTAssertTrue(response.statusCode == 500)
                } else {
                    XCTFail("This should be a ReactiveAPIError.httpError")
            }
            default: XCTFail("This should throws an error!")
        }
    }
}
