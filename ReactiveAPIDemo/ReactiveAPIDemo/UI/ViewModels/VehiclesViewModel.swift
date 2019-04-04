import Foundation
import RxSwift

final class VehiclesViewModel: ViewModel {
    override func apiCall() -> Single<[ViewModelData]> {
        return client.getVehicles(url: url)
            .map { data in
                data.results.map {
                    ViewModelData(
                        title: $0.name,
                        subtitle: "Max Speed: \($0.maxAtmospheringSpeed) Km/h",
                        url: $0.url
                    )
                }
        }
    }
}

final class VehicleViewModel: ViewModel {
    override func apiCall() -> Single<[ViewModelData]> {
        return client.getVehicle(url: url)
            .map { data in
                return [
                    ViewModelData(title: data.name, subtitle: "Name", url: data.url),
                    ViewModelData(title: data.model, subtitle: "Model", url: data.url),
                    ViewModelData(title: data.manufacturer, subtitle: "Manufacturer", url: data.url),
                    ViewModelData(title: data.vehicleClass, subtitle: "Vehicle Class", url: data.url),
                    ViewModelData(title: data.crew, subtitle: "Crew", url: data.url),
                    ViewModelData(title: data.passengers, subtitle: "Passengers", url: data.url),
                    ViewModelData(title: data.cargoCapacity, subtitle: "Cargo Capacity (Kg)", url: data.url),
                    ViewModelData(title: data.maxAtmospheringSpeed, subtitle: "Max Speed (Km/h)", url: data.url),
                    ViewModelData(title: data.length, subtitle: "Length (m)", url: data.url),
                    ViewModelData(title: data.consumables, subtitle: "Consumables", url: data.url),
                    ViewModelData(title: data.costInCredits, subtitle: "Cost in credits", url: data.url),
                    ViewModelData(title: "\(data.pilots.count)", subtitle: "Known Pilots", url: data.url),
                    ViewModelData(title: "\(data.films.count)", subtitle: "Films", url: data.url)
                ]
        }
    }
}
