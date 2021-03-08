import XCTest
import RxSwift
import OHHTTPStubs
import Combine

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
                                                              renewToken: { Single.just("renewToken") },
                                                              renewToken1: { Just("renewToken")
                                                                .mapError { ReactiveAPIError.map($0) }
                                                                .eraseToAnyPublisher() })

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

    func test_requestWithNewToken_When200_DataIsValid_Combine() {
        let session = URLSessionMock.create(Resources.json)
        do {
            let response = try await(authenticator.requestWithNewToken1(session: session,
                                                                        request: Resources.urlRequest,
                                                                        newToken: "newToken"))
            XCTAssertNotNil(response)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_requestWithNewToken_When200_DataIsValid_Comparison() {
        let session = URLSessionMock.create(Resources.json)
        do {
            let response1 = try authenticator.requestWithNewToken(session: session.rx,
                                                                 request: Resources.urlRequest,
                                                                 newToken: "newToken")
                .toBlocking()
                .single()

            let response2 = try await(authenticator.requestWithNewToken1(session: session,
                                                                         request: Resources.urlRequest,
                                                                         newToken: "newToken"))

            XCTAssertNotNil(response1)
            XCTAssertNotNil(response2)
            XCTAssertEqual(response1, response2)
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

    func test_requestWithNewToken_When500_ReturnError_Combine() {
        let session = URLSessionMock.create(Resources.json, errorCode: 500)
        do {
            _ = try await(authenticator.requestWithNewToken1(session: session,
                                                             request: Resources.urlRequest,
                                                             newToken: "newToken"))

            XCTFail("This should throws an error!")
        } catch {
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

    func test_Fetch_When401_ReturnError_Combine() {
        let session = URLSessionMock.create(Resources.json, errorCode: 401)
        do {
            _ = try await(authenticator.requestWithNewToken1(session: session,
                                                             request: Resources.urlRequest,
                                                             newToken: "newToken"))

            XCTFail("This should throws an error!")
        } catch {
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
                                                          renewToken: { Single.just("renewToken") },
                                                          renewToken1: { Just("renewToken")
                                                            .mapError { ReactiveAPIError.map($0) }
                                                            .eraseToAnyPublisher() })
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

    func test_Authenticate_When401_ReturnNil_Combine() {
        let session = URLSessionMock.create(Resources.json)
        let authenticator = ReactiveAPITokenAuthenticator(tokenHeaderName: "tokenHeaderName",
                                                          getCurrentToken: { nil },
                                                          renewToken: { Single.just("renewToken") },
                                                          renewToken1: { Just("renewToken")
                                                            .mapError { ReactiveAPIError.map($0) }
                                                            .eraseToAnyPublisher() })
        do {
            let response = try authenticator.authenticate1(session: session,
                                                          request: Resources.urlRequest,
                                                          response: Resources.httpUrlResponse(code: 401)!,
                                                          data: nil)?
                .waitForCompletion()
                .first

            XCTAssertNil(response)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_Authenticate_When401_ReturnNil_Comparison() {
        let session = URLSessionMock.create(Resources.json)
        let authenticator = ReactiveAPITokenAuthenticator(tokenHeaderName: "tokenHeaderName",
                                                          getCurrentToken: { nil },
                                                          renewToken: { Single.just("renewToken") },
                                                          renewToken1: { Just("renewToken")
                                                            .mapError { ReactiveAPIError.map($0) }
                                                            .eraseToAnyPublisher() })
        do {
            let response1 = try authenticator.authenticate(session: session.rx,
                                                          request: Resources.urlRequest,
                                                          response: Resources.httpUrlResponse(code: 401)!,
                                                          data: nil)?
                .toBlocking()
                .single()

            let response2 = try authenticator.authenticate1(session: session,
                                                           request: Resources.urlRequest,
                                                           response: Resources.httpUrlResponse(code: 401)!,
                                                           data: nil)?
                .waitForCompletion()
                .first

            XCTAssertNil(response1)
            XCTAssertNil(response2)
            XCTAssertEqual(response1, response2)
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

    func test_Authenticate_WhenGetCurrentTokenNil_ReturnNil_Combine() {
        let session = URLSessionMock.create(Resources.json)
        do {
            let response = try authenticator.authenticate1(session: session,
                                                           request: Resources.urlRequest,
                                                           response: Resources.httpUrlResponse(code: 500)!,
                                                           data: nil)?
                .waitForCompletion()
                .first

            XCTAssertNil(response)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_Authenticate_WhenGetCurrentTokenNil_ReturnNil_Comparison() {
        let session = URLSessionMock.create(Resources.json)
        do {
            let response1 = try authenticator.authenticate(session: session.rx,
                                                          request: Resources.urlRequest,
                                                          response: Resources.httpUrlResponse(code: 500)!,
                                                          data: nil)?
                .toBlocking()
                .single()

            let response2 = try authenticator.authenticate1(session: session,
                                                           request: Resources.urlRequest,
                                                           response: Resources.httpUrlResponse(code: 500)!,
                                                           data: nil)?
                .waitForCompletion()
                .first

            XCTAssertNil(response1)
            XCTAssertNil(response2)
            XCTAssertEqual(response1, response2)
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

    func test_Authenticate_WhenIsRenewingTokenTrue_RequestWithNewToken_Combine() {
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
                                                            }},
                                                          renewToken1: {
                                                            sut.renewToken1().tryMap {
                                                                currentToken = $0.name
                                                                return $0.name
                                                            }
                                                            .mapError { ReactiveAPIError.map($0) }
                                                            .eraseToAnyPublisher()
                                                          })
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

    func test_multiple_parallel_failed_requests_should_trigger_a_single_token_refresh_and_be_retried_after_refresh_Combine() {
        // Given
        let queueAscheduler = DispatchQueue(label: "queueA", attributes: .concurrent)
        let queueBscheduler = DispatchQueue(label: "queueB", attributes: .concurrent)
        let queueCscheduler = DispatchQueue(label: "queueC", attributes: .concurrent)

        var loginCounter = 0
        var renewCounter = 0
        var singleActionCounter = 0
        var parallelActionCounter = 0
        var callCounter = 0
        var currentToken = ""

        let tokenHeaderName = "tokenHeaderName"
        let sut = MockAPI(session: URLSession.shared, baseUrl: Resources.baseUrl)

        sut.authenticator = ReactiveAPITokenAuthenticator(tokenHeaderName: tokenHeaderName,
                                                          getCurrentToken: { currentToken },
                                                          renewToken: {
                                                            sut.renewToken().map {
                                                                currentToken = $0.name
                                                                return $0.name
                                                            }},
                                                          renewToken1: {
                                                            sut.renewToken1().tryMap {
                                                                currentToken = $0.name
                                                                return $0.name
                                                            }
                                                            .mapError { ReactiveAPIError.map($0) }
                                                            .eraseToAnyPublisher()
                                                          })
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
            let loginResponse = try await(sut.login1())
            currentToken = loginResponse.name
            _ = try await(sut.authenticatedSingleAction1())

            let parallelCall1 = sut.authenticatedParallelAction1()
                .print("\(Date().dateMillis) Parallel call 1 on \(Thread.current.description)")
                .subscribe(on: queueAscheduler)

            let parallelCall2 = sut.authenticatedParallelAction1()
                .print("\(Date().dateMillis) Parallel call 2 on \(Thread.current.description)")
                .subscribe(on: queueBscheduler)

            let parallelCall3 = sut.authenticatedParallelAction1()
                .print("\(Date().dateMillis) Parallel call 3 on \(Thread.current.description)")
                .subscribe(on: queueCscheduler)

            // When
            let events = try awaitCompletion(of: Publishers.Zip3(parallelCall1, parallelCall2, parallelCall3))

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
