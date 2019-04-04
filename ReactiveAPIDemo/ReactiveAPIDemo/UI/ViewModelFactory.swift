import Foundation

protocol ViewModelFactory {
    func hasViewModel(for indexPath: IndexPath) -> Bool
    func viewModel(for indexPath: IndexPath, data: [ViewModelData]) -> ViewModel?
    func childViewModelFactory(for indexPath: IndexPath, data: [ViewModelData]) -> ViewModelFactory?
}
