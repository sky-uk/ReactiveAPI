import Foundation

// See https://tools.ietf.org/html/rfc7231#section-4.3
public enum ReactiveAPIHTTPMethod: String {
    // Issues https://forums.swift.org/t/sr-6405-urlrequest-does-not-capitalise-http-methods/7087
    case connect = "CONNECT"
    case delete  = "DELETE"
    case get     = "GET"
    case head    = "HEAD"
    case options = "OPTIONS"
    case patch   = "PATCH"
    case post    = "POST"
    case put     = "PUT"
    case trace   = "TRACE"
}
