import XCTest
import Swifter
@testable import ReactiveAPI

class RefreshTokenTests: SkyTestCase {

    private let authenticator = ReactiveAPITokenAuthenticator(tokenHeaderName: "tokenHeaderName",
                                                              getCurrentToken: { "getCurrentToken" },
                                                              renewToken: { "renewToken" })

    func testRefreshToken() async {
        // Given
        do {
            let token1 = "token1"
            let token2 = "token2"
            var currentToken = token1

            let tokenHeaderName = "token-header-name"
            let sut = ClientAPI(session: URLSession.shared, baseUrl: URL(string: "http://127.0.0.1:8080")!)

            let renewToken = try await sut.renewToken() // TODO

            sut.authenticator = ReactiveAPITokenAuthenticator(tokenHeaderName: tokenHeaderName, getCurrentToken: { currentToken }, renewToken: {
                currentToken = renewToken.name
                return renewToken.name
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
            _ = try await sut.login()

            async let endpointCall1 = sut.endpoint1()
            async let endpointCall2 = sut.endpoint2()

            let events = try await [endpointCall1, endpointCall2]

            // Then
            XCTAssertNotNil(events)
            XCTAssertEqual(endpointCallCountToken2, 2)
            XCTAssertEqual(endpointCallCountToken1, 2)
        } catch {
            XCTFail("\(error)")
        }
    }
}

private class ClientAPI: ReactiveAPI {
    struct Endpoint {
        static let login = "/login"
        static let renew = "/renew"
        static let endpoint1 = "/end-point/1/call"
        static let endpoint2 = "/end-point/2/call"

    }

    func login() async throws -> Model {
        return try await request(url: absoluteURL(ClientAPI.Endpoint.login))
    }

    func renewToken() async throws -> Model {
        let url = absoluteURL(ClientAPI.Endpoint.renew)
        return try await request(url: url)
    }

    func endpoint1() async throws -> Model {
        return try await request(url: absoluteURL(Endpoint.endpoint1))
    }

    func endpoint2() async throws -> Model {
        return try await request(url: absoluteURL(Endpoint.endpoint2))
    }
}

// Struct
private struct Model: Codable {
    let name: String
    let id: String
}

extension Model {
    static func mock(name: String = "", id: String = UUID().uuidString) -> Model {
        return Model(name: name, id: id)
    }
}

extension Encodable {
    func encoded() -> Data {
        do {
            return try JSONHelper.encode(value: self)
        } catch {
            fatalError("\(error)")
        }
    }
}
