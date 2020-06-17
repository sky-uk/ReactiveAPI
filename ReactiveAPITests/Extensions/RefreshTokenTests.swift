
import XCTest
import RxSwift
import Swifter
@testable import ReactiveAPI
class RefreshTokenTests: SkyTestCase {

    private let authenticator = ReactiveAPITokenAuthenticator(tokenHeaderName: "tokenHeaderName",
                                                              getCurrentToken: { "getCurrentToken" },
                                                              renewToken: { Single.just("renewToken") })

    func testRefreshToken() {
        // Given
        do {
            let token1 = "token1"
            let token2 = "token2"
            var currentToken = token1

            let tokenHeaderName = "token-header-name"
            let sut = ClientAPI(session: URLSession.shared.rx, baseUrl: URL(string: "http://127.0.0.1:8080")!)

            sut.authenticator = ReactiveAPITokenAuthenticator(tokenHeaderName: tokenHeaderName, getCurrentToken: { currentToken }, renewToken: {
                sut.renewToken().map {
                    currentToken = $0.name
                    return $0.name
                }
            })

            sut.requestInterceptors += [ TokenInterceptor(tokenValue: { return currentToken }, headerName: tokenHeaderName) ]

            httpServer.route(ClientAPI.Endpoint.login) { (request, callCount) -> (HttpResponse) in
                XCTAssertLessThanOrEqual(callCount, 2)
                switch callCount {
                    case 1:
                        XCTAssertEqual(request.header(name: tokenHeaderName), token1)
                        return HttpResponse.ok(Model.mock().encoded())
                    default:
                        XCTFail("switch endLoginCall")
                }
                return HttpResponse.unauthorized
            }

            httpServer.route(ClientAPI.Endpoint.renew) { (request, callCount) -> (HttpResponse) in
                XCTAssertLessThanOrEqual(callCount, 1)
                return HttpResponse.ok(Model.mock(name: token2).encoded())
            }

            var endpointCallCountToken2 = 0
            httpServer.route("/end-point/:path/call") { (request, callCount) -> (HttpResponse) in
                let token = request.header(name: tokenHeaderName)
                XCTAssertNotNil(token)
                XCTAssertTrue(callCount <= 2 ? token == token1 : token == token2)
                switch token {
                    case token1:
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
            let _ = try sut.login().toBlocking().single()

            let endpointCall1 = sut.endpoint1().subscribeOn(ConcurrentDispatchQueueScheduler(queue: DispatchQueue.init(label: "queue1")))
            let endpointCall2 = sut.endpoint2().subscribeOn(ConcurrentDispatchQueueScheduler(queue: DispatchQueue.init(label: "queue2")))

            let events = try Single.zip(endpointCall1, endpointCall2).toBlocking().single()

            // Then
            XCTAssertNotNil(events)
            XCTAssertEqual(endpointCallCountToken2, 2)
        } catch {
            XCTFail("\(error)")
        }
    }
}

class ClientAPI: ReactiveAPI {
    struct Endpoint {
        static let login = "/login"
        static let renew = "/renew"
        static let endpoint1 = "/end-point/1/call"
        static let endpoint2 = "/end-point/2/call"

    }

    func login() -> Single<Model> {
        return request(url: absoluteURL(ClientAPI.Endpoint.login))
    }

    func renewToken() -> Single<Model> {
        let url = absoluteURL(ClientAPI.Endpoint.renew)
        return request(url: url)
    }

    func endpoint1() -> Single<Model> {
        return request(url: absoluteURL(Endpoint.endpoint1))
    }

    func endpoint2() -> Single<Model> {
        return request(url: absoluteURL(Endpoint.endpoint2))
    }
}


// Struct
struct Model: Codable {
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
