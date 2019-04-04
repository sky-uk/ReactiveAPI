import Foundation

struct Person: Codable, Hashable {
    let name: String
    let birthYear: String
    let eyeColor: String
    let gender: String
    let hairColor: String
    let height: String
    let mass: String
    let skinColor: String
    let homeworld: URL
    let films: [URL]
    let species: [URL]
    let starships: [URL]
    let vehicles: [URL]
    let url: URL
}
