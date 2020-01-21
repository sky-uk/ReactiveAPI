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

    func test_multiple_parallel_failed_requests_should_trigger_a_single_token_refresh_and_be_retried_after_refresh() {
        // Given
        var loginCounter = 0
        var renewCounter = 0
        var singleActionCounter = 0
        var parallelActionCounter = 0
        var callCounter = 0
        var currentToken = ""

        let tokenHeaderName = "tokenHeaderName"
        let sut = MockAPI(session: URLSession.shared.rx, baseUrl: Resources.baseUrl)

        sut.authenticator = ReactiveAPITokenAuthenticator(tokenHeaderName: tokenHeaderName,
                                                          getCurrentToken: { currentToken },
                                                          renewToken: {
                                                            sut.renewToken().map {
                                                                currentToken = $0.name
                                                                return $0.name
                                                            }})
        sut.requestInterceptors += [
            TokenInterceptor(tokenValue: { currentToken }, headerName: tokenHeaderName)
        ]

        stub(condition: isHost(Resources.baseUrlHost)) { request -> OHHTTPStubsResponse in
            callCounter += 1
            print("\(callCounter) Request: \(request.url!.absoluteString)")

            do {
                if (request.urlHasSuffix(MockAPI.loginEndpoint)) {
                    loginCounter += 1
                    return try JSONHelper.jsonHttpResponse(value: ModelMock(name: "oldToken", id: 1))
                }

                if (request.urlHasSuffix(MockAPI.renewEndpoint)) {
                    renewCounter += 1
                    return try JSONHelper.jsonHttpResponse(value: ModelMock(name: "newToken", id: 2))
                }

                if (request.urlHasSuffix(MockAPI.authenticatedSingleActionEndpoint)) {
                    singleActionCounter += 1
                    return try JSONHelper.jsonHttpResponse(value: ModelMock(name: "singleAction", id: 3))
                }

                if (request.urlHasSuffix(MockAPI.authenticatedParallelActionEndpoint)) {
                    parallelActionCounter += 1
                    if (request.value(forHTTPHeaderField: tokenHeaderName) == "oldToken") {
                        return JSONHelper.unauthorized401()
                    }
                    return try JSONHelper.jsonHttpResponse(value: ModelMock(name: "parallelAction", id: 4))
                }
            } catch {
                XCTFail("\(error)")
            }

            return JSONHelper.stubError()
        }

        do {
            let loginResponse = try sut.login().toBlocking().single()
            currentToken = loginResponse.name
            let _ = try sut.authenticatedSingleAction().toBlocking().single()

            let parallelCall1 = sut.authenticatedParallelAction()
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .do(onSubscribed: {
                    print("Parallel call 1 on \(Thread.current.description)")

                })
            let parallelCall2 = sut.authenticatedParallelAction()
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .do(onSubscribed: {
                    print("Parallel call 2 on \(Thread.current.description)")

                })
            let parallelCall3 = sut.authenticatedParallelAction()
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .do(onSubscribed: {
                    print("Parallel call 3 on \(Thread.current.description)")

                })

            // When
            let events = try Single.zip(parallelCall1, parallelCall2, parallelCall3)
                .toBlocking()
                .single()

            // Then
            XCTAssertNotNil(events)
            XCTAssertEqual(loginCounter, 1)
            XCTAssertEqual(renewCounter, 1)
            XCTAssertEqual(singleActionCounter, 1)
            XCTAssertEqual(parallelActionCounter, 6)
        } catch {
            XCTFail("\(error)")
        }
    }
}


class MockAPI: ReactiveAPI {

    public static let loginEndpoint = "login"
    public static let renewEndpoint = "renew"
    public static let authenticatedSingleActionEndpoint = "auth-action"
    public static let authenticatedParallelActionEndpoint = "auth-parallel-action"

    func login() -> Single<ModelMock> {
        return request(url: absoluteURL(MockAPI.loginEndpoint))
    }

    func renewToken() -> Single<ModelMock> {
        return request(url: absoluteURL(MockAPI.renewEndpoint))
    }

    func authenticatedSingleAction() -> Single<ModelMock> {
        return request(url: absoluteURL(MockAPI.authenticatedSingleActionEndpoint))
    }

    func authenticatedParallelAction() -> Single<ModelMock> {
        return request(url: absoluteURL(MockAPI.authenticatedParallelActionEndpoint))
    }
}

public class TokenInterceptor : ReactiveAPIRequestInterceptor {

    private let tokenValue: () -> String
    private let headerName: String

    public init(tokenValue: @escaping () -> String, headerName: String) {
        self.tokenValue = tokenValue
        self.headerName = headerName
    }

    public func intercept(_ request: URLRequest) -> URLRequest {
        var mutableRequest = request
        mutableRequest.addValue(tokenValue(), forHTTPHeaderField: headerName)
        return mutableRequest
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
