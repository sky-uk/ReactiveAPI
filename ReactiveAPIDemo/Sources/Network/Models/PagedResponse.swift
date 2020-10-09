import Foundation

struct PagedResponse<T>: Codable, Hashable where T: Codable, T: Hashable {
    let count: Int
    let previous: URL?
    let next: URL?
    let results: [T]
}
