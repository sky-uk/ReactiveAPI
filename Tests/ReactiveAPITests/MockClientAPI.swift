import XCTest
import RxSwift
import Combine
import ReactiveAPI

class ClientAPI: ReactiveAPI {
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
