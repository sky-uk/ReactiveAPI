import XCTest
import RxSwift
import OHHTTPStubs
@testable import ReactiveAPI

class ReactiveAPITokenAuthenticatorTests: XCTestCase {
    override func setUp() {
        super.setUp()
        OHHTTPStubs.removeAllStubs()
        OHHTTPStubs.onStubActivation { (request, _, _) in
            debugPrint("Stubbed: \(String(describing: request.url))")
        }
    }

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

    func test_Authenticate_When401_ReturnNil() {
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

    func test_Authenticate_WhenGetCurrentTokenNil_ReturnNil() {
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


    func test_Authenticate_WhenRenewTokenSucceeded_AndRequest500_RetrunError() {
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

    func test_Authenticate_WhenRenewTokenFails_RetrunError() {
        let session = URLSessionMock.create(Resources.json)
        let authenticator = ReactiveAPITokenAuthenticator(tokenHeaderName: "tokenHeaderName",
                                                          getCurrentToken: { "getCurrentToken" },
                                                          renewToken: { Single.error(ReactiveAPIError.unknown) })

        let response = authenticator.authenticate(session: session.rx,
                                                  request: Resources.urlRequest,
                                                  response: Resources.httpUrlResponse(code: 401)!,
                                                  data: nil)?
            .toBlocking()
            .materialize()

        switch response {
            case .failed(elements: _, error: let error):
                if case let ReactiveAPIError.httpError(request: _, response: response, data: _) = error {
                    XCTAssertTrue(response.statusCode == 401)
                } else {
                    XCTFail("This should be a ReactiveAPIError.httpError")
            }
            default: XCTFail("This should throws an error!")
        }
    }

    func test() {
        // Given
        var renewCounter = 0
        let renewToken: () -> Single<String> = {
            return Observable.just( { renewCounter += 1; return "renewCounter" }() ).share().asSingle()
        }
        let sut = MockAPI(session: URLSession.shared.rx, baseUrl: Resources.baseUrl)
        let authenticator = ReactiveAPITokenAuthenticator(tokenHeaderName: "", getCurrentToken: { "" }, renewToken: renewToken)
        sut.authenticator = authenticator

        var callCounter = 0
        stub(condition: isHost("www.mock.com")) { request -> OHHTTPStubsResponse in
            print("\(callCounter) Request: \(request.url!.absoluteString) - \(renewCounter)")
            do {
                switch callCounter {
                    case 0:
                        XCTAssertTrue(request.url!.absoluteString == "http://www.mock.com/endpoint1")
                        callCounter += 1
                        return JSONHelper.unauthorized401()
                    case 1:
                        XCTAssertTrue(request.url!.absoluteString == "http://www.mock.com/endpoint1")
                        callCounter += 1
                        return JSONHelper.unauthorized401()
                    case 2:
                        XCTAssertTrue(request.url!.absoluteString == "http://www.mock.com/endpoint1")
                        callCounter += 1
                        return try JSONHelper.jsonHttpResponse(value: ModelMock(name: "secondo", id: 2))
                    case 3:
                        XCTAssertTrue(request.url!.absoluteString == "http://www.mock.com/endpoint1")
                        callCounter += 1
                        return try JSONHelper.jsonHttpResponse(value: ModelMock(name: "secondo", id: 2))
                    default:
                        return JSONHelper.stubError()

                }
            } catch {
                XCTFail("\(error)")
            }
            return JSONHelper.stubError()
        }

        do {
            let response1 = sut.getModel1()
            let response2 = sut.getModel1()

            // When
            let events = try Single.zip(response1, response2)
                .toBlocking()
                .single()

            // Then
            XCTAssertNotNil(events)
            XCTAssertEqual(renewCounter, 1)

        } catch {
            XCTFail("\(error)")
        }
    }
}


class MockAPI: ReactiveAPI {
    func getModel1() -> Single<ModelMock> {
        return request(url: absoluteURL("endpoint1"))
    }

    func getModel2() -> Single<ModelMock> {
        return request(url: absoluteURL("endpoint2"))
    }
}

public class JSONHelper {
    public enum StubError: Error {
        case inconsitency
    }

    public static func stubError() -> OHHTTPStubsResponse {
        return OHHTTPStubsResponse(error: StubError.inconsitency)
    }
    static private let jsonContentType = ["Content-Type": "application/json"]

    public static func jsonHttpResponse<T: Encodable>(value: T) throws -> OHHTTPStubsResponse {
        let json = try JSONHelper.encode(value: value)
        return OHHTTPStubsResponse(data: json,
                                   statusCode: 200,
                                   headers: jsonContentType)
    }

    public static func unauthorized401() -> OHHTTPStubsResponse {
        return OHHTTPStubsResponse(data: Data(), statusCode: 401, headers: [:])
    }

    public static func encode<T: Encodable>(value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom({ (date, encoder) in
            var container = encoder.singleValueContainer()
            let encodedDate = ISO8601DateFormatter().string(from: date)
            try container.encode(encodedDate)
        })
        return try encoder.encode(value)
    }
}
