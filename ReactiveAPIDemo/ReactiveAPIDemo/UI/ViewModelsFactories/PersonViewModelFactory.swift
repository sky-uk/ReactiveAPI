import Foundation
import RxSwift

class SingleViewModelFactory: ViewModelFactory {
    
    private let client: StarWarsAPI
    private let viewModel: ViewModel
    
    init(client: StarWarsAPI, viewModel: ViewModel) {
        self.client = client
        self.viewModel = viewModel
    }
    
    func hasViewModel(for indexPath: IndexPath) -> Bool {
        return true
    }
    
    func viewModel(for indexPath: IndexPath, data: [ViewModelData]) -> ViewModel? {
        return viewModel
    }
    
    func childViewModelFactory(for indexPath: IndexPath) -> ViewModelFactory? {
        return nil
    }
}
