import Foundation

public struct TokenPair: Codable {
    public let shortLivedToken: String
    public let renewToken: String

    public init(shortLivedToken: String, renewToken: String) {
        self.shortLivedToken = shortLivedToken
        self.renewToken = renewToken
    }
}
