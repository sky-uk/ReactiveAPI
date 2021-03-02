import XCTest
import RxSwift
import Combine
import Swifter
@testable import ReactiveAPI

class RedirectTests: SkyTestCase {

    private let authenticator = ReactiveAPITokenAuthenticator(tokenHeaderName: "tokenHeaderName",
                                                              getCurrentToken: { "getCurrentToken" },
                                                              renewToken: { Single.just("renewToken") },
                                                              renewToken1: { Just("renewToken")
                                                                .mapError { ReactiveAPIError.map($0) }
                                                                .eraseToAnyPublisher() })

    func testRedirect() throws {
        // Given
        let queueScheduler00 = ConcurrentDispatchQueueScheduler(queue: DispatchQueue.init(label: "queue00"))
        let queueScheduler01 = ConcurrentDispatchQueueScheduler(queue: DispatchQueue.init(label: "queue01"))
        let queueScheduler02 = ConcurrentDispatchQueueScheduler(queue: DispatchQueue.init(label: "queue02"))

        var callCountEndpoint1 = 0
        var callCountEndpoint2 = 0

        let token1 = "token1"
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
        let call00 = sut.endpoint1().do(onSubscribed: {
            print("\(Date().dateMillis) Parallel call  on \(Thread.current.description)")
        }).subscribeOn(queueScheduler00)

        let call01 = sut.endpoint1().do(onSubscribed: {
            print("\(Date().dateMillis) Parallel call  on \(Thread.current.description)")
        }).subscribeOn(queueScheduler01)

        let call02 = sut.endpoint1().do(onSubscribed: {
            print("\(Date().dateMillis) Parallel call on \(Thread.current.description)")
        }).subscribeOn(queueScheduler02)


        let streamed = try Single.zip(call00, call01, call02).toBlocking().single()
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

    func login() -> Single<Model> {
        return request(url: absoluteURL(ClientAPI.Endpoint.login))
    }

    func login1() -> AnyPublisher<Model, ReactiveAPIError> {
        return request1(url: absoluteURL(ClientAPI.Endpoint.login))
    }

    func renewToken() -> Single<Model> {
        let url = absoluteURL(ClientAPI.Endpoint.renew)
        return request(url: url)
    }

    func renewToken1() -> AnyPublisher<Model, ReactiveAPIError> {
        let url = absoluteURL(ClientAPI.Endpoint.renew)
        return request1(url: url)
    }

    func endpoint1() -> Single<Model> {
        return request(url: absoluteURL(Endpoint.endpoint1))
    }

    func endpoint2() -> Single<Model> {
        return request(url: absoluteURL(Endpoint.endpoint2))
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


