import Foundation

extension URLRequest {
    mutating func setHeaders(_ headers: [String: Any?]) {
        headers
            .compactMapValues { $0 }
            .forEach { setValue("\($1)", forHTTPHeaderField: $0) }
    }

    static func createForJSON(with url: URL,
                              method: ReactiveAPIHTTPMethod = .get,
                              headers: [String: Any?]? = nil,
                              queryParams: [String: Any?]? = nil,
                              bodyParams: [String: Any?]? = nil,
                              queryStringTypeConverter: ReactiveAPITypeConverter?) throws -> URLRequest {
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
            else { throw ReactiveAPIError.URLComponentsError(url) }

        queryParams.map { urlComponents.setQueryParams($0, queryStringTypeConverter: queryStringTypeConverter) }

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if method == .post || method == .put || method == .patch {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            if let bodyDict = bodyParams?.compactMapValues({ $0 }) {
                request.httpBody = try JSONSerialization.data(withJSONObject: bodyDict)
            }
        }

        headers.map { request.setHeaders($0) }

        return request
    }

    static func createForJSON(with url: URL,
                              method: ReactiveAPIHTTPMethod = .get,
                              headers: [String: Any?]? = nil,
                              queryParams: [String: Any?]? = nil,
                              body: Encodable? = nil,
                              encoder: JSONEncoder,
                              queryStringTypeConverter: ReactiveAPITypeConverter?) throws -> URLRequest {
        return try createForJSON(with: url,
                                 method: method,
                                 headers: headers,
                                 queryParams: queryParams,
                                 bodyParams: body?.dictionary(with: encoder),
                                 queryStringTypeConverter: queryStringTypeConverter)
    }
}
