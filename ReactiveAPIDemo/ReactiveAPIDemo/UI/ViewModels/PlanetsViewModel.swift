import Foundation
import RxSwift

class PlanetsViewModel: ViewModel {
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
