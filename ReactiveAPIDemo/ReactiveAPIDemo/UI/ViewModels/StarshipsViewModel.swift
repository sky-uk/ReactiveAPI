import Foundation
import RxSwift

class StarshipsViewModel: ViewModel {
    override func apiCall() -> Single<[ViewModelData]> {
        return client.getStarships(url: url)
            .map { data in
                data.results.map {
                    ViewModelData(
                        title: $0.name,
                        subtitle: "Hyperdrive rating: \($0.hyperdrive_rating)",
                        url: $0.url
                    )
                }
        }
    }
}
