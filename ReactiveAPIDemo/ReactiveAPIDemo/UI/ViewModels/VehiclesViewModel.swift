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
