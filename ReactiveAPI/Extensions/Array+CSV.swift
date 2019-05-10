import Foundation

extension Array {
    public var csv: String {
        return compactMap { "\($0)" }.joined(separator: ",")
    }
}
