import Foundation

public extension URLComponents {
    mutating func setQueryParams(_ params: [String: Any?]) {
        queryItems = (queryItems ?? []) + params
            .compactMapValues { $0 }
            .compactMap { URLQueryItem(name: $0, value: "\($1)") }
    }
}
