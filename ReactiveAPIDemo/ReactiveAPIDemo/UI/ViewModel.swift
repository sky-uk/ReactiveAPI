import Foundation
import RxCocoa
import RxSwift

struct ViewModelData {
    let title: String
    let subtitle: String
    let url: URL
}

class ViewModel {
    
    internal let client: StarWarsAPI
    internal let url: URL
    
    init(client: StarWarsAPI, url: URL) {
        self.client = client
        self.url = url
    }
    
    func apiCall() -> Single<[ViewModelData]> {
        return Observable.empty().asSingle()
    }
    
    final func fetch(controller: ListController) {
        apiCall()
            .asDriver(onErrorRecover: { error in
                print("Something bad happened: \(error)")
                return Driver.empty()
            })
            .drive(onNext: { controller.data = $0 })
            .disposed(by: controller.disposeBag)
    }
}
