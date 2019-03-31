import Foundation
import RxSwift

class RootViewModelFactory: ViewModelFactory {
    
    private let client: StarWarsAPI
    
    init(client: StarWarsAPI) {
        self.client = client
    }
    
    func hasViewModel(for indexPath: IndexPath) -> Bool {
        return indexPath.row >= 0 && indexPath.row <= 5
    }
    
    func viewModel(for indexPath: IndexPath, data: [ViewModelData]) -> ViewModel? {
        switch indexPath.row {
        case 0:
            return FilmsViewModel(client: client, url: data[indexPath.row].url)
        case 1:
            return PeopleViewModel(client: client, url: data[indexPath.row].url)
        case 2:
            return PlanetsViewModel(client: client, url: data[indexPath.row].url)
        case 3:
            return SpeciesViewModel(client: client, url: data[indexPath.row].url)
        case 4:
            return VehiclesViewModel(client: client, url: data[indexPath.row].url)
        case 5:
            return StarshipsViewModel(client: client, url: data[indexPath.row].url)
        default:
            return nil
        }
    }
    
    func childViewModelFactory(for indexPath: IndexPath, data: [ViewModelData]) -> ViewModelFactory? {
        switch indexPath.row {
        case 0:
            return SingleViewModelFactory(client: client,
                                          creator: { [unowned self] indexPath, data in
                                            FilmViewModel(client: self.client, url: data[indexPath.row].url) })
        case 1:
            return SingleViewModelFactory(client: client,
                                          creator: { [unowned self] indexPath, data in
                                            PersonViewModel(client: self.client, url: data[indexPath.row].url) })
        case 2:
            return SingleViewModelFactory(client: client,
                                          creator: { [unowned self] indexPath, data in
                                            PlanetViewModel(client: self.client, url: data[indexPath.row].url) })
        case 3:
            return SingleViewModelFactory(client: client,
                                          creator: { [unowned self] indexPath, data in
                                            SpecieViewModel(client: self.client, url: data[indexPath.row].url) })
        case 4:
            return SingleViewModelFactory(client: client,
                                          creator: { [unowned self] indexPath, data in
                                            VehicleViewModel(client: self.client, url: data[indexPath.row].url) })
        case 5:
            return SingleViewModelFactory(client: client,
                                          creator: { [unowned self] indexPath, data in
                                            StarshipViewModel(client: self.client, url: data[indexPath.row].url) })
        default:
            return nil
        }
    }
}
