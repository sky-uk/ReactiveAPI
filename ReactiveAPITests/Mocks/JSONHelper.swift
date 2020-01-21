import Foundation
import OHHTTPStubs

public class JSONHelper {
    public enum StubError: Error {
        case inconsitency
    }

    public static func stubError() -> OHHTTPStubsResponse {
        return OHHTTPStubsResponse(error: StubError.inconsitency)
    }
    static private let jsonContentType = ["Content-Type": "application/json"]

    public static func jsonHttpResponse<T: Encodable>(value: T) throws -> OHHTTPStubsResponse {
        let json = try JSONHelper.encode(value: value)
        return OHHTTPStubsResponse(data: json,
                                   statusCode: 200,
                                   headers: jsonContentType)
    }

    public static func unauthorized401() -> OHHTTPStubsResponse {
        return OHHTTPStubsResponse(data: Data(), statusCode: 401, headers: [:])
    }

    public static func encode<T: Encodable>(value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom({ (date, encoder) in
            var container = encoder.singleValueContainer()
            let encodedDate = ISO8601DateFormatter().string(from: date)
            try container.encode(encodedDate)
        })
        return try encoder.encode(value)
    }
}
