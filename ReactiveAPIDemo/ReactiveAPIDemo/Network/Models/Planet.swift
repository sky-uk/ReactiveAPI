import Foundation

struct Planet: Codable, Hashable {
    let name: String
    let diameter: String
    let rotation_period: String
    let orbital_period: String
    let gravity: String
    let population: String
    let climate: String
    let terrain: String
    let surface_water: String
    let residents: [URL]
    let films: [URL]
    let url: URL
}
