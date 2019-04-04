import Foundation

struct Planet: Codable, Hashable {
    let name: String
    let diameter: String
    let rotationPeriod: String
    let orbitalPeriod: String
    let gravity: String
    let population: String
    let climate: String
    let terrain: String
    let surfaceWater: String
    let residents: [URL]
    let films: [URL]
    let url: URL
}
