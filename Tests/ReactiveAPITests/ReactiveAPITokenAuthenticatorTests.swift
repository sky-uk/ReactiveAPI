import XCTest
import OHHTTPStubs

@testable import ReactiveAPI

class ReactiveAPITokenAuthenticatorTests: XCTestCase {
    override func setUp() {
        super.setUp()
        HTTPStubs.removeAllStubs()
        HTTPStubs.onStubActivation { (request, _, _) in
            debugPrint("Stubbed: \(String(describing: request.url))")
        }
    }

    private let authenticator = ReactiveAPITokenAuthenticator(tokenHeaderName: "tokenHeaderName",
                                                              getCurrentToken: { "getCurrentToken" },
                                                              renewToken: { "renewToken" })

    func test_requestWithNewToken_When200_DataIsValid() async {
        let session = URLSessionMock.create(Resources.json)
        do {
            let response = try await authenticator.requestWithNewToken(session: session,
                                                                       request: Resources.urlRequest,
                                                                       newToken: "newToken")

            XCTAssertNotNil(response)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_requestWithNewToken_When500_ReturnError() async {
        let session = URLSessionMock.create(Resources.json, errorCode: 500)
        do {
            let _ = try await authenticator.requestWithNewToken(session: session,
                                                                request: Resources.urlRequest,
                                                                newToken: "newToken")
            XCTFail("This should throws an error!")
        } catch {
            if case let ReactiveAPIError.httpError(request: _, response: response, data: _) = error {
                XCTAssertTrue(response.statusCode == 500)
            } else {
                XCTFail("This should be a ReactiveAPIError.httpError")
            }
        }
    }

    func test_Fetch_When401_ReturnError() async {
        let session = URLSessionMock.create(Resources.json, errorCode: 401)
        do {
            let _ = try await authenticator.requestWithNewToken(session: session,
                                                                request: Resources.urlRequest,
                                                                newToken: "newToken")
            XCTFail("This should throws an error!")
        } catch {
            if case let ReactiveAPIError.httpError(request: _, response: response, data: _) = error {
                XCTAssertTrue(response.statusCode == 401)
            } else {
                XCTFail("This should be a ReactiveAPIError.httpError")
            }
        }
    }

    func test_Authenticate_When401_ReturnNil() async {
        let session = URLSessionMock.create(Resources.json)
        let authenticator = ReactiveAPITokenAuthenticator(tokenHeaderName: "tokenHeaderName",
                                                          getCurrentToken: { nil },
                                                          renewToken: { "renewToken" })
        do {
            let response = try await authenticator.authenticate(session: session,
                                                          request: Resources.urlRequest,
                                                          response: Resources.httpUrlResponse(code: 401)!,
                                                          data: nil)

            XCTAssertNil(response)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_Authenticate_WhenGetCurrentTokenNil_ReturnNil() async {
        let session = URLSessionMock.create(Resources.json)
        do {
            let response = try await authenticator.authenticate(session: session,
                                                          request: Resources.urlRequest,
                                                          response: Resources.httpUrlResponse(code: 500)!,
                                                          data: nil)

            XCTAssertNil(response)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_Authenticate_WhenIsRenewingTokenTrue_RequestWithNewToken() async {
        let session = URLSessionMock.create(Resources.json)
        authenticator.setNewToken(token: "token", isRenewing: true)
        do {
            let response = try await authenticator.authenticate(session: session,
                                                          request: Resources.urlRequest,
                                                          response: Resources.httpUrlResponse(code: 401)!,
                                                          data: nil)

            XCTAssertNotNil(response)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_Authenticate_RenewToken() async {
        let session = URLSessionMock.create(Resources.json)
        do {
            let response = try await authenticator.authenticate(session: session,
                                                          request: Resources.urlRequest,
                                                          response: Resources.httpUrlResponse(code: 401)!,
                                                          data: nil)

            XCTAssertNotNil(response)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_Authenticate_WhenRenewTokenSucceeded_AndRequest500_RetrunError() async {
        let session = URLSessionMock.create(Resources.json, errorCode: 500)
        do {
            let _ = try await authenticator.authenticate(session: session,
                                                      request: Resources.urlRequest,
                                                      response: Resources.httpUrlResponse(code: 401)!,
                                                      data: nil)
            XCTFail("This should throws an error!")
        } catch {
            if case let ReactiveAPIError.httpError(request: _, response: response, data: _) = error {
                XCTAssertTrue(response.statusCode == 500)
            } else {
                XCTFail("This should be a ReactiveAPIError.httpError")
            }
        }
    }

    /*
    func test_multiple_parallel_failed_requests_should_trigger_a_single_token_refresh_and_be_retried_after_refresh() {
        // Given
        let queueAscheduler = ConcurrentDispatchQueueScheduler(queue: DispatchQueue.init(label: "queueA"))
        let queueBscheduler = ConcurrentDispatchQueueScheduler(queue: DispatchQueue.init(label: "queueB"))
        let queueCscheduler = ConcurrentDispatchQueueScheduler(queue: DispatchQueue.init(label: "queueC"))

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

        stub(condition: isHost(Resources.baseUrlHost)) { request -> HTTPStubsResponse in
            callCounter += 1
            print("\(callCounter) Request: \(request.url!.absoluteString)")

            do {
                if request.urlHasSuffix(MockAPI.loginEndpoint) {
                    loginCounter += 1
                    return try JSONHelper.jsonHttpResponse(value: ModelMock(name: "oldToken", id: 1))
                }

                if request.urlHasSuffix(MockAPI.renewEndpoint) {
                    renewCounter += 1
                    return try JSONHelper.jsonHttpResponse(value: ModelMock(name: "newToken", id: 2))
                }

                if request.urlHasSuffix(MockAPI.authenticatedSingleActionEndpoint) {
                    singleActionCounter += 1
                    return try JSONHelper.jsonHttpResponse(value: ModelMock(name: "singleAction", id: 3))
                }

                if request.urlHasSuffix(MockAPI.authenticatedParallelActionEndpoint) {
                    parallelActionCounter += 1
                    if request.value(forHTTPHeaderField: tokenHeaderName) == "oldToken" {
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
            _ = try sut.authenticatedSingleAction().toBlocking().single()

            let parallelCall1 = sut.authenticatedParallelAction()
                .do(onSubscribed: {
                    print("\(Date().dateMillis) Parallel call 1 on \(Thread.current.description)")

                }).subscribeOn(queueAscheduler)

            let parallelCall2 = sut.authenticatedParallelAction()
                .do(onSubscribed: {
                    print("\(Date().dateMillis) Parallel call 2 on \(Thread.current.description)")

                }).subscribeOn(queueBscheduler)

            let parallelCall3 = sut.authenticatedParallelAction()
                .do(onSubscribed: {
                    print("\(Date().dateMillis) Parallel call 3 on \(Thread.current.description)")

                }).subscribeOn(queueCscheduler)

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
    */
}
