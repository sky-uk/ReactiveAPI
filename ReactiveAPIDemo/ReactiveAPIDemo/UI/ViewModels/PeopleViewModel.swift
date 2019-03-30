import Foundation
import RxSwift

class PeopleViewModel: ViewModel {
    override func apiCall() -> Single<[ViewModelData]> {
        return client.getPeople(url: url)
            .map { data in
                data.results.map {
                    ViewModelData(
                        title: $0.name,
                        subtitle: "Birth Year: \($0.birth_year)",
                        url: $0.url
                    )
                }
        }
    }
}
