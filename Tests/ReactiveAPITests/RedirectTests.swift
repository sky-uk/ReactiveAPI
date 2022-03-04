import XCTest
import Swifter
@testable import ReactiveAPI

class RedirectTests: SkyTestCase {

    private let authenticator = ReactiveAPITokenAuthenticator(tokenHeaderName: "tokenHeaderName",
                                                              getCurrentToken: { "getCurrentToken" },
                                                              renewToken: { "renewToken" })

    func testRedirect() async throws {
        // Given
        var callCountEndpoint1 = 0
        var callCountEndpoint2 = 0

        let token1 = "token1"
        var currentToken = token1
        let tokenHeaderName = "token-header-name"
        let sut = ClientAPI(session: URLSession.shared, baseUrl: URL(string: "http://127.0.0.1:8080")!)
        let renewToken = try await sut.renewToken() // TODO
        sut.authenticator = ReactiveAPITokenAuthenticator(tokenHeaderName: tokenHeaderName, getCurrentToken: { currentToken }, renewToken: {
            currentToken = renewToken.name
            return renewToken.name
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
        async let call00 = sut.endpoint1()
        async let call01 = sut.endpoint1()
        async let call02 = sut.endpoint1()

        let streamed = try await [call00, call01, call02]
        // Then
        XCTAssertNotNil(streamed)
        XCTAssertEqual(callCountEndpoint1, 3)
        XCTAssertEqual(callCountEndpoint2, 3)
    }
}

fileprivate class ClientAPI: ReactiveAPI {
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

    func endpoint1() async throws -> Model { // TODO
//        print("pino")
//        sleep(1000)
//        print("dopo sleep")
        return try await request(url: absoluteURL(Endpoint.endpoint1))
    }

    func endpoint2() async throws -> Model {
        return try await request(url: absoluteURL(Endpoint.endpoint2))
    }

    // Struct

}

fileprivate struct Model: Codable {
    let name: String
    let id: String
}

extension Model {
    fileprivate static func mock(name: String = "", id: String = UUID().uuidString) -> Model {
        return Model(name: name, id: id)
    }
}
/*
extension Encodable {
    func encoded() -> Data {
        do {
            return try JSONHelper.encode(value: self)
        } catch {
            fatalError("\(error)")
        }
    }
}
*/


