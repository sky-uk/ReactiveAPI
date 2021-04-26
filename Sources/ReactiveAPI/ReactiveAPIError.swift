import Foundation

private func reduce(_ codingKeys: [CodingKey]) -> String {
    return codingKeys.reduce("root") { accumulator, key in
        accumulator + (key.intValue.map { "[\($0)]" } ?? ".\(key.stringValue)")
    }
}

public enum ReactiveAPIError: Error {
    case decodingError(_ underlyingError: DecodingError)
    case URLComponentsError(URL)
    case httpError(request: URLRequest, response: HTTPURLResponse, data: Data)
    case nonHttpResponse(response: URLResponse)
    case missingResponseData(request: URLRequest)
    case networkError(urlError: URLError)
    case generic(error: Error)

    static func map(_ error: Error) -> ReactiveAPIError {
        if let urlerror = error as? URLError {
            return .networkError(urlError: urlerror)
        }

        return (error as? ReactiveAPIError) ?? .generic(error: error)
    }
}

extension ReactiveAPIError: LocalizedError {
    public var errorDescription: String? {
        switch self {
            case .decodingError(let underlyingError):
                return underlyingError.localizedDescription
            default:
                return nil
        }
    }

    public var failureReason: String? {
        switch self {
            case .decodingError(let underlyingError):
                switch underlyingError {
                    case DecodingError.keyNotFound(let key, let context):
                        let fullPath = context.codingPath + [key]
                        return "\(reduce(fullPath)): Not Found!"
                    case DecodingError.typeMismatch(_, let context),
                         DecodingError.valueNotFound(_, let context),
                         DecodingError.dataCorrupted(let context):
                        return "\(reduce(context.codingPath)): \(context.debugDescription)"
                    default:
                        return underlyingError.failureReason
                }
            default:
                return nil
        }
    }
}
