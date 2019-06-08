import Foundation

public extension URLComponents {
    mutating func setQueryParams(_ params: [String: Any?],
                                 queryStringTypeConverter: ReactiveAPITypeConverter? = nil) {
        queryItems = (queryItems ?? []) + params
            .compactMapValues { queryStringTypeConverter?($0) ?? $0 }
            .compactMap { URLQueryItem(name: $0, value: "\($1)") }
    }
}
