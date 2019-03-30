import Foundation

struct Specie: Codable, Hashable {
    let name: String
    let classification: String
    let designation: String
    let average_height: String
    let average_lifespan: String
    let eye_colors: String
    let hair_colors: String
    let skin_colors: String
    let language: String
    let homeworld: String
    let people: [URL]
    let films: [URL]
    let url: URL
}
