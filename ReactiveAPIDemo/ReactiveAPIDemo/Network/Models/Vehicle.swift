import Foundation

struct Vehicle: Codable, Hashable {
    let name: String
    let model: String
    let vehicle_class: String
    let manufacturer: String
    let length: String
    let cost_in_credits: String
    let crew: String
    let passengers: String
    let max_atmosphering_speed: String
    let cargo_capacity: String
    let consumables: String
    let films: [URL]
    let pilots: [URL]
    let url: URL
}
