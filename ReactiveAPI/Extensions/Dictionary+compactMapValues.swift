import Foundation

// Proposal for Swift 5
// https://github.com/apple/swift-evolution/blob/master/proposals/0218-introduce-compact-map-values.md
extension Dictionary {
    public func compactMapValues<T>(_ transform: (Value) throws -> T?) rethrows -> [Key: T] {
        return try self.reduce(into: [Key: T](), { (result, x) in
            if let value = try transform(x.value) {
                result[x.key] = value
            }
        })
    }
}
