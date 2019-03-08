import Foundation

extension Array {
    public var csv: String {
        return map { String(describing: $0) }.joined(separator: ",")
    }
}
