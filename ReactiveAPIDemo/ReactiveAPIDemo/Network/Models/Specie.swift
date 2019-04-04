import Foundation

struct Specie: Codable, Hashable {
    let name: String
    let classification: String
    let designation: String
    let averageHeight: String
    let averageLifespan: String
    let eyeColors: String
    let hairColors: String
    let skinColors: String
    let language: String
    let homeworld: String
    let people: [URL]
    let films: [URL]
    let url: URL
}
