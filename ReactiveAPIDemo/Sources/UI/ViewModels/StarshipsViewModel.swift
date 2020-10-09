import Foundation
import RxSwift

final class StarshipsViewModel: ViewModel {
    override func apiCall() -> Single<[ViewModelData]> {
        return client.getStarships(url: url)
            .map { data in
                data.results.map {
                    ViewModelData(
                        title: $0.name,
                        subtitle: "Hyperdrive rating: \($0.hyperdriveRating)",
                        url: $0.url
                    )
                }
        }
    }
}

final class StarshipViewModel: ViewModel {
    override func apiCall() -> Single<[ViewModelData]> {
        return client.getStarship(url: url)
            .map { data in
                return [
                    ViewModelData(title: data.name, subtitle: "Name", url: data.url),
                    ViewModelData(title: data.model, subtitle: "Model", url: data.url),
                    ViewModelData(title: data.manufacturer, subtitle: "Manufacturer", url: data.url),
                    ViewModelData(title: data.starshipClass, subtitle: "Starship Class", url: data.url),
                    ViewModelData(title: data.hyperdriveRating, subtitle: "Hyperdrive rating", url: data.url),
                    ViewModelData(title: data.crew, subtitle: "Crew", url: data.url),
                    ViewModelData(title: data.passengers, subtitle: "Passengers", url: data.url),
                    ViewModelData(title: data.cargoCapacity, subtitle: "Cargo Capacity (Kg)", url: data.url),
                    ViewModelData(title: data.maxAtmospheringSpeed, subtitle: "Max Speed (Km/h)", url: data.url),
                    ViewModelData(title: data.MGLT, subtitle: "Megalights per hour (MGLT)", url: data.url),
                    ViewModelData(title: data.length, subtitle: "Length (m)", url: data.url),
                    ViewModelData(title: data.consumables, subtitle: "Consumables", url: data.url),
                    ViewModelData(title: data.costInCredits, subtitle: "Cost in credits", url: data.url),
                    ViewModelData(title: "\(data.pilots.count)", subtitle: "Known Pilots", url: data.url),
                    ViewModelData(title: "\(data.films.count)", subtitle: "Films", url: data.url)
                ]
        }
    }
}
