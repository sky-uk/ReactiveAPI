import Foundation

// See https://tools.ietf.org/html/rfc7231#section-4.3
public enum ReactiveAPIHTTPMethod : String {
    case connect
    case delete
    case get
    case head
    case options
    case patch
    case post
    case put
    case trace
}
