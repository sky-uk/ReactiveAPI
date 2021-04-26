import XCTest
import Combine
import Swifter
@testable import ReactiveAPI

class RedirectTests: SkyTestCase {

    private let authenticator = ReactiveAPITokenAuthenticator(tokenHeaderName: "tokenHeaderName",
                                                              getCurrentToken: { "getCurrentToken" },
                                                              renewToken: { Just("renewToken")
                                                                .mapError { ReactiveAPIError.map($0) }
                                                                .eraseToAnyPublisher() })

    func testRedirect() throws {
        // Given
        let queueScheduler00 = DispatchQueue(label: "queue00", attributes: .concurrent)
        let queueScheduler01 = DispatchQueue(label: "queue01", attributes: .concurrent)
        let queueScheduler02 = DispatchQueue(label: "queue02", attributes: .concurrent)


        var callCountEndpoint1 = 0
        var callCountEndpoint2 = 0

        let token1 = "token1"
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

        httpServer.route(ClientAPI.Endpoint.endpoint1) { (request, callCount) -> (HttpResponse) in
            callCountEndpoint1 = callCount
            XCTAssertEqual(request.header(name: tokenHeaderName), token1)
            return HttpResponse.raw(302, "", ["Location" : "http://127.0.0.1:8080\(ClientAPI.Endpoint.endpoint2)"]) { (writer) in
                try writer.write(Data())
            }
        }

        httpServer.route(ClientAPI.Endpoint.endpoint2) { (request, callCount) -> (HttpResponse) in
            callCountEndpoint2 = callCount
            XCTAssertEqual(request.header(name: tokenHeaderName), token1)
            return HttpResponse.ok(Model.mock().encoded())
        }

        try startServer()
        // When
        let call00 = sut.endpoint1()
            .print("\(Date().dateMillis) Parallel call  on \(Thread.current.description)")
            .subscribe(on: queueScheduler00)

        let call01 = sut.endpoint1()
            .print("\(Date().dateMillis) Parallel call  on \(Thread.current.description)")
            .subscribe(on: queueScheduler01)

        let call02 = sut.endpoint1()
            .print("\(Date().dateMillis) Parallel call on \(Thread.current.description)")
            .subscribe(on: queueScheduler02)


        let streamed = try awaitCompletion(of: Publishers.Zip3(call00, call01, call02))

        // Then
        XCTAssertNotNil(streamed)
        XCTAssertEqual(callCountEndpoint1, 3)
        XCTAssertEqual(callCountEndpoint2, 3)
    }
}
