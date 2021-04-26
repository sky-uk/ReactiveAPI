import XCTest
import Combine
import Swifter
@testable import ReactiveAPI

class RefreshTokenTests: SkyTestCase {

    private let authenticator = ReactiveAPITokenAuthenticator(tokenHeaderName: "tokenHeaderName",
                                                              getCurrentToken: { "getCurrentToken" },
                                                              renewToken: { Just("renewToken")
                                                                .mapError { ReactiveAPIError.map($0) }
                                                                .eraseToAnyPublisher() })

    func testRefreshToken() {
        // Given
        let queueScheduler00 = DispatchQueue(label: "queue00", attributes: .concurrent)
        let queueScheduler01 = DispatchQueue(label: "queue01", attributes: .concurrent)

        do {
            let token1 = "token1"
            let token2 = "token2"
            var currentToken = token1

            let tokenHeaderName = "token-header-name"
            let sut = ClientAPI(session: URLSession.shared, baseUrl: URL(string: "http://127.0.0.1:8080")!)

            sut.authenticator = ReactiveAPITokenAuthenticator(tokenHeaderName: tokenHeaderName, getCurrentToken: { currentToken }, renewToken: {
                sut.renewToken().tryMap {
                    currentToken = $0.name
                    return $0.name
                }
                .mapError { ReactiveAPIError.map($0) }
                .eraseToAnyPublisher()
            })

            sut.requestInterceptors += [ TokenInterceptor(tokenValue: { return currentToken }, headerName: tokenHeaderName) ]

            httpServer.route(ClientAPI.Endpoint.login) { (request, callCount) -> (HttpResponse) in
                XCTAssertEqual(callCount, 1)
                XCTAssertEqual(request.header(name: tokenHeaderName), token1)
                return HttpResponse.ok(Model.mock().encoded())
            }

            httpServer.route(ClientAPI.Endpoint.renew) { (request, callCount) -> (HttpResponse) in
                print("Request:\(request.path)  Thread.current:\(Thread.current)")
                XCTAssertEqual(callCount, 1)
                return HttpResponse.ok(Model.mock(name: token2).encoded())
            }

            var endpointCallCountToken2 = 0
            var endpointCallCountToken1 = 0
            httpServer.route("/end-point/:path/call") { (request, callCount) -> (HttpResponse) in
                print("Request:\(request.path)  Thread.current:\(Thread.current)")
                let token = request.header(name: tokenHeaderName)
                XCTAssertNotNil(token)
                XCTAssertTrue(callCount <= 2 ? token == token1 : token == token2)
                switch token {
                    case token1:
                        endpointCallCountToken1 += 1
                        sleep(callCount == 1 ? 4 : 0)
                        return HttpResponse.unauthorized
                    case token2:
                        endpointCallCountToken2 += 1
                        return HttpResponse.ok(Model.mock().encoded())
                    default:
                        XCTFail("Should not receive: \(request)")
                        return HttpResponse.notFound
                }
            }

            try startServer()
            // When
            _ = try sut.login().waitForCompletion()

            let endpointCall1 = sut.endpoint1()
                .print("\(Date().dateMillis) Parallel call  on \(Thread.current.description)")
                .subscribe(on: queueScheduler00)
            let endpointCall2 = sut.endpoint2()
                .print("\(Date().dateMillis) Parallel call  on \(Thread.current.description)")
                .subscribe(on: queueScheduler01)

            let events = try awaitCompletion(of: Publishers.Zip(endpointCall1, endpointCall2))

            // Then
            XCTAssertNotNil(events)
            XCTAssertEqual(endpointCallCountToken2, 2)
            XCTAssertEqual(endpointCallCountToken1, 2)
        } catch {
            XCTFail("\(error)")
        }
    }
}
