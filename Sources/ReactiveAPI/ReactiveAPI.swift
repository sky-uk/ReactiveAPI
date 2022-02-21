import Foundation

open class ReactiveAPI: ReactiveAPIProtocol {
    public let session: URLSession
    public let decoder: ReactiveAPIDecoder
    public let encoder: JSONEncoder
    public let baseUrl: URL
    public var authenticator: ReactiveAPIAuthenticator?
    public var requestInterceptors: [ReactiveAPIRequestInterceptor] = []
    public var cache: ReactiveAPICache?
    public var queryStringTypeConverter: ReactiveAPITypeConverter?

    required public init(session: URLSession,
                         decoder: ReactiveAPIDecoder = JSONDecoder(),
                         encoder: JSONEncoder = JSONEncoder(),
                         baseUrl: URL) {
        self.session = session
        self.decoder = decoder
        self.encoder = encoder
        self.baseUrl = baseUrl
    }
}

@available(*, deprecated, renamed: "ReactiveAPI")
open class JSONReactiveAPI: ReactiveAPI {}
