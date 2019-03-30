import Foundation
import RxSwift

class FilmsViewModel: ViewModel {
    override func apiCall() -> Single<[ViewModelData]> {
        return client.getFilms(url: url)
            .map { data in
                data.results.map {
                    ViewModelData(
                        title: $0.title,
                        subtitle: "Release date: \($0.release_date)",
                        url: $0.url
                    )
                }
        }
    }
}
