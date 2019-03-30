import Foundation

struct Person: Codable, Hashable {
    let name: String
    let birth_year: String
    let eye_color: String
    let gender: String
    let hair_color: String
    let height: String
    let mass: String
    let skin_color: String
    let homeworld: URL
    let films: [URL]
    let species: [URL]
    let starships: [URL]
    let vehicles: [URL]
    let url: URL
}
