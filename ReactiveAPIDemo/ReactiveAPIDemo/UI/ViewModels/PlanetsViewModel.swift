import Foundation
import RxSwift

final class PlanetsViewModel: ViewModel {
    override func apiCall() -> Single<[ViewModelData]> {
        return client.getPlanets(url: url)
            .map { data in
                data.results.map {
                    ViewModelData(
                        title: $0.name,
                        subtitle: "Climate: \($0.climate)",
                        url: $0.url
                    )
                }
        }
    }
}

final class PlanetViewModel: ViewModel {
    override func apiCall() -> Single<[ViewModelData]> {
        return client.getPlanet(url: url)
            .map { data in
                return [
                    ViewModelData(title: data.name, subtitle: "Name", url: data.url),
                    ViewModelData(title: data.diameter, subtitle: "Diameter (Km)", url: data.url),
                    ViewModelData(title: data.orbitalPeriod, subtitle: "Orbital Period (days)", url: data.url),
                    ViewModelData(title: data.rotationPeriod, subtitle: "Rotation Period (hours)", url: data.url),
                    ViewModelData(title: data.gravity, subtitle: "Gravity", url: data.url),
                    ViewModelData(title: data.climate, subtitle: "Climate", url: data.url),
                    ViewModelData(title: "\(data.surfaceWater)%", subtitle: "Covered with water", url: data.url),
                    ViewModelData(title: data.terrain, subtitle: "Terrain", url: data.url),
                    ViewModelData(title: data.population, subtitle: "Population", url: data.url),
                    ViewModelData(title: "\(data.residents.count)", subtitle: "Known Characters live here", url: data.url),
                    ViewModelData(title: "\(data.films.count)", subtitle: "Films", url: data.url)
                ]
        }
    }
}
