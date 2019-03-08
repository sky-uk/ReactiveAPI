import Foundation

public enum ReactiveAPIError: Error {
    case jsonDeserializationError(String, Data)
    case URLComponentsError(URL)
    case httpError(response: HTTPURLResponse, data: Data)
}
