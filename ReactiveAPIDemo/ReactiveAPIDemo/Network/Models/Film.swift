import Foundation

struct Film: Codable, Hashable {
    let title: String
    let episodeId: Int
    let openingCrawl: String
    let director: String
    let producer: String
    let releaseDate: String
    let species: [URL]
    let starships: [URL]
    let vehicles: [URL]
    let characters: [URL]
    let planets: [URL]
    let url: URL
}
