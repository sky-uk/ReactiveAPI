import Foundation
import RxSwift

class VehiclesViewModel: ViewModel {
    override func apiCall() -> Single<[ViewModelData]> {
        return client.getVehicles(url: url)
            .map { data in
                data.results.map {
                    ViewModelData(
                        title: $0.name,
                        subtitle: "Max Speed: \($0.max_atmosphering_speed) Km/h",
                        url: $0.url
                    )
                }
        }
    }
}

class VehicleViewModel: ViewModel {
    override func apiCall() -> Single<[ViewModelData]> {
        return client.getVehicle(url: url)
            .map { data in
                return [
                    ViewModelData(title: data.name, subtitle: "Name", url: data.url),
                    ViewModelData(title: data.model, subtitle: "Model", url: data.url),
                    ViewModelData(title: data.manufacturer, subtitle: "Manufacturer", url: data.url),
                    ViewModelData(title: data.vehicle_class, subtitle: "Vehicle Class", url: data.url),
                    ViewModelData(title: data.crew, subtitle: "Crew", url: data.url),
                    ViewModelData(title: data.passengers, subtitle: "Passengers", url: data.url),
                    ViewModelData(title: data.cargo_capacity, subtitle: "Cargo Capacity (Kg)", url: data.url),
                    ViewModelData(title: data.max_atmosphering_speed, subtitle: "Max Speed (Km/h)", url: data.url),
                    ViewModelData(title: data.length, subtitle: "Length (m)", url: data.url),
                    ViewModelData(title: data.consumables, subtitle: "Consumables", url: data.url),
                    ViewModelData(title: data.cost_in_credits, subtitle: "Cost in credits", url: data.url),
                    ViewModelData(title: "\(data.pilots.count)", subtitle: "Known Pilots", url: data.url),
                    ViewModelData(title: "\(data.films.count)", subtitle: "Films", url: data.url)
                ]
        }
    }
}
