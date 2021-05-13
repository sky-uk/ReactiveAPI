import XCTest
import Swifter
import Combine

@testable import ReactiveAPI

class ReactiveAPITokenAuthenticatorTests: SkyTestCase {

    private let authenticator = ReactiveAPITokenAuthenticator(tokenHeaderName: "tokenHeaderName",
                                                              getCurrentToken: { "getCurrentToken" },
                                                              renewToken: { Just("renewToken")
                                                                .setFailureType(to: ReactiveAPIError.self)
                                                                .eraseToAnyPublisher() })
    
    func test_requestWithNewToken_When200_DataIsValid() {
        let session = URLSessionMock.create(Resources.json)
        do {
            let response = try awaitCompletion(authenticator.requestWithNewToken(session: session,
                                                                       request: Resources.urlRequest,
                                                                       newToken: "newToken"))
            XCTAssertNotNil(response)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func test_requestWithNewToken_When500_ReturnError() {
        let session = URLSessionMock.create(Resources.json, errorCode: 500)
        do {
            _ = try awaitCompletion(authenticator.requestWithNewToken(session: session,
                                                            request: Resources.urlRequest,
                                                            newToken: "newToken"))
            
            XCTFail("This should throw an error!")
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
        do {
            _ = try awaitCompletion(authenticator.requestWithNewToken(session: session,
                                                            request: Resources.urlRequest,
                                                            newToken: "newToken"))
            
            XCTFail("This should throw an error!")
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
                                                          renewToken: { Just("renewToken")
                                                            .setFailureType(to: ReactiveAPIError.self)
                                                            .eraseToAnyPublisher() })
        do {
            let response = try authenticator.authenticate(session: session,
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
    
    func test_Authenticate_WhenGetCurrentTokenNil_ReturnNil() {
        let session = URLSessionMock.create(Resources.json)
        do {
            let response = try authenticator.authenticate(session: session,
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
    
    func test_Authenticate_WhenIsRenewingTokenTrue_RequestWithNewToken() {
        let session = URLSessionMock.create(Resources.json)
        authenticator.setNewToken(token: "token", isRenewing: true)
        do {
            let response = try authenticator.authenticate(session: session,
                                                          request: Resources.urlRequest,
                                                          response: Resources.httpUrlResponse(code: 401)!,
                                                          data: nil)?
                .waitForCompletion()
                .first
            
            XCTAssertNotNil(response)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func test_Authenticate_RenewToken_Combine() {
        let session = URLSessionMock.create(Resources.json)
        do {
            let response = try authenticator.authenticate(session: session,
                                                          request: Resources.urlRequest,
                                                          response: Resources.httpUrlResponse(code: 401)!,
                                                          data: nil)?
                .waitForCompletion()
                .first
            
            XCTAssertNotNil(response)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func test_Authenticate_WhenRenewTokenSucceeded_AndRequest500_RetrunError() {
        let session = URLSessionMock.create(Resources.json, errorCode: 500)
        do {
            _ = try awaitCompletion(authenticator.authenticate(session: session,
                                                     request: Resources.urlRequest,
                                                     response: Resources.httpUrlResponse(code: 401)!,
                                                     data: nil)!)
            
            XCTFail("This should throw an error!")
        } catch {
            if case let ReactiveAPIError.httpError(request: _, response: response, data: _) = error {
                XCTAssertTrue(response.statusCode == 500)
            } else {
                XCTFail("This should be a ReactiveAPIError.httpError")
            }
        }
    }
    
    func test_multiple_parallel_failed_requests_should_trigger_a_single_token_refresh_and_be_retried_after_refresh() throws {
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
        
        let tokenHeaderName = "tokenheadername"
        let sut = MockAPI(session: URLSession.shared, baseUrl: Resources.baseUrl)
        
        sut.authenticator = ReactiveAPITokenAuthenticator(tokenHeaderName: tokenHeaderName,
                                                          getCurrentToken: { currentToken },
                                                          renewToken: {
                                                            sut.renewToken().tryMap {
                                                                currentToken = $0.name
                                                                return $0.name
                                                            }
                                                            .mapError { ReactiveAPIError.map($0) }
                                                            .eraseToAnyPublisher()
                                                          })
        sut.requestInterceptors += [
            TokenInterceptor(tokenValue: { currentToken }, headerName: tokenHeaderName)
        ]

        httpServer.route(MockAPI.loginEndpoint) { (request, callCount) -> (HttpResponse) in
            callCounter += 1
            loginCounter += 1
            return HttpResponse.ok(ModelMock(name: "oldToken", id: 1).encoded())
        }

        httpServer.route(MockAPI.renewEndpoint) { (request, callCount) -> (HttpResponse) in
            callCounter += 1
            renewCounter += 1
            return HttpResponse.ok(ModelMock(name: "newToken", id: 2).encoded())
        }

        httpServer.route(MockAPI.authenticatedSingleActionEndpoint) { (request, callCount) -> (HttpResponse) in
            callCounter += 1
            singleActionCounter += 1
            return HttpResponse.ok(ModelMock(name: "singleAction", id: 3).encoded())
        }

        httpServer.route(MockAPI.authenticatedParallelActionEndpoint) { (request, callCount) -> (HttpResponse) in
            callCounter += 1
            parallelActionCounter += 1
            if request.header(name: tokenHeaderName) == "oldToken" {
                return HttpResponse.unauthorized
            }
            return HttpResponse.ok(ModelMock(name: "parallelAction", id: 4).encoded())
        }

        try startServer()

        do {
            let loginResponse = try awaitCompletion(sut.login())
            currentToken = loginResponse.name
            _ = try awaitCompletion(sut.authenticatedSingleAction())
            
            let parallelCall1 = sut.authenticatedParallelAction()
                .print("\(Date().dateMillis) Parallel call 1 on \(Thread.current.description)")
                .subscribe(on: queueAscheduler)
            
            let parallelCall2 = sut.authenticatedParallelAction()
                .print("\(Date().dateMillis) Parallel call 2 on \(Thread.current.description)")
                .subscribe(on: queueBscheduler)
            
            let parallelCall3 = sut.authenticatedParallelAction()
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
