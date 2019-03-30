import Foundation

struct Starship: Codable, Hashable {
    let name: String
    let model: String
    let starship_class: String
    let manufacturer: String
    let cost_in_credits: String
    let length: String
    let crew: String
    let passengers: String
    let max_atmosphering_speed: String
    let hyperdrive_rating: String
    let MGLT: String
    let cargo_capacity: String
    let consumables: String
    let films: [URL]
    let pilots: [URL]
    let url: URL
}
