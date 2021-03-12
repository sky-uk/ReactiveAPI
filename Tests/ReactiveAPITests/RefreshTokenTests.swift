import XCTest
import RxSwift
import Combine
import Swifter
@testable import ReactiveAPI

class RefreshTokenTests: SkyTestCase {

    private let authenticator = ReactiveAPITokenAuthenticator(tokenHeaderName: "tokenHeaderName",
                                                              getCurrentToken: { "getCurrentToken" },
                                                              renewToken: { Single.just("renewToken") },
                                                              renewToken1: { Just("renewToken")
                                                                .mapError { ReactiveAPIError.map($0) }
                                                                .eraseToAnyPublisher() })

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
            }, renewToken1: {
                sut.renewToken1().tryMap {
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
            _ = try sut.login().toBlocking().single()

            let endpointCall1 = sut.endpoint1().subscribeOn(ConcurrentDispatchQueueScheduler(queue: DispatchQueue.init(label: "queue1")))
            let endpointCall2 = sut.endpoint2().subscribeOn(ConcurrentDispatchQueueScheduler(queue: DispatchQueue.init(label: "queue2")))

            let events = try Single.zip(endpointCall1, endpointCall2).toBlocking().single()

            // Then
            XCTAssertNotNil(events)
            XCTAssertEqual(endpointCallCountToken2, 2)
            XCTAssertEqual(endpointCallCountToken1, 2)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testRefreshToken_Combine() {
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
                sut.renewToken().map {
                    currentToken = $0.name
                    return $0.name
                }
            }, renewToken1: {
                sut.renewToken1().tryMap {
                    currentToken = $0.name
                    return $0.name
                }
                .mapError { ReactiveAPIError.map($0) }
                .eraseToAnyPublisher()
            })

            sut.requestInterceptors += [ TokenInterceptor(tokenValue: { return currentToken }, headerName: tokenHeaderName) ]

            httpServer.route(ClientAPI.Endpoint.login) { (request, callCount) -> (HttpResponse) in
                XCTAssertEqual(callCount, 1) // TODO: è successo che una volta su CI è fallito il test perchè qui c'era 2. Ricontrollare bene il meccanismo di sincronizzazione del semaforo in route
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
            _ = try sut.login1().waitForCompletion()

            let endpointCall1 = sut.endpoint1_1()
                .print("\(Date().dateMillis) Parallel call  on \(Thread.current.description)")
                .subscribe(on: queueScheduler00)
            let endpointCall2 = sut.endpoint2_1()
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

private class ClientAPI: ReactiveAPI { // TODO: Perchè questa classe è replicata qui?
    struct Endpoint {
        static let login = "/login"
        static let renew = "/renew"
        static let endpoint1 = "/end-point/1/call"
        static let endpoint2 = "/end-point/2/call"

    }

    func login() -> Single<Model> {
        request(url: absoluteURL(ClientAPI.Endpoint.login))
    }

    func login1() -> AnyPublisher<Model, ReactiveAPIError> {
        request1(url: absoluteURL(ClientAPI.Endpoint.login))
    }

    func renewToken() -> Single<Model> {
        request(url: absoluteURL(ClientAPI.Endpoint.renew))
    }

    func renewToken1() -> AnyPublisher<Model, ReactiveAPIError> {
        request1(url: absoluteURL(ClientAPI.Endpoint.renew))
    }

    func endpoint1() -> Single<Model> {
        request(url: absoluteURL(Endpoint.endpoint1))
    }

    func endpoint1_1() -> AnyPublisher<Model, ReactiveAPIError> {
        request1(url: absoluteURL(Endpoint.endpoint1))
    }

    func endpoint2() -> Single<Model> {
        request(url: absoluteURL(Endpoint.endpoint2))
    }

    func endpoint2_1() -> AnyPublisher<Model, ReactiveAPIError> {
        request1(url: absoluteURL(Endpoint.endpoint2))
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
