import Foundation
import RxSwift

class SpeciesViewModel: ViewModel {
    override func apiCall() -> Single<[ViewModelData]> {
        return client.getSpecies(url: url)
            .map { data in
                data.results.map {
                    ViewModelData(
                        title: $0.name,
                        subtitle: "Average height: \($0.average_height)",
                        url: $0.url
                    )
                }
        }
    }
}
