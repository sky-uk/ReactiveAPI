import Foundation
import RxSwift

typealias SingleViewModelCreator = (_ indexPath: IndexPath, _ data: [ViewModelData]) -> ViewModel?

final class SingleViewModelFactory: ViewModelFactory {

    private let client: StarWarsAPI
    private let creator: SingleViewModelCreator

    init(client: StarWarsAPI, creator: @escaping SingleViewModelCreator) {
        self.client = client
        self.creator = creator
    }

    func hasViewModel(for indexPath: IndexPath) -> Bool {
        return true
    }

    func viewModel(for indexPath: IndexPath, data: [ViewModelData]) -> ViewModel? {
        return creator(indexPath, data)
    }

    func childViewModelFactory(for indexPath: IndexPath, data: [ViewModelData]) -> ViewModelFactory? {
        return nil
    }
}
