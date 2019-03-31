import Foundation
import RxSwift

class RootViewModel: ViewModel {
    override func apiCall() -> Single<[ViewModelData]> {
        return client.getRoot()
            .map { root in
                return [
                    ViewModelData(title: "Films", subtitle: "All the films in the saga", url: root.films),
                    ViewModelData(title: "People", subtitle: "Meet the characters", url: root.people),
                    ViewModelData(title: "Planets", subtitle: "Discover all the worlds", url: root.planets),
                    ViewModelData(title: "Species", subtitle: "Embrace all the cultures", url: root.species),
                    ViewModelData(title: "Vehicles", subtitle: "Take a ride", url: root.vehicles),
                    ViewModelData(title: "Starships", subtitle: "Reach distant places fast", url: root.starships)
                ]
        }
    }
}
