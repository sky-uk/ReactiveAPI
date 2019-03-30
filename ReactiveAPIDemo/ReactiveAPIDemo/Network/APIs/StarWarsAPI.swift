import Foundation
import ReactiveAPI
import RxSwift

class StarWarsAPI: JSONReactiveAPI {
    
    func getRoot() -> Single<Root> {
        return request(url: absoluteURL(""))
    }
    
    func getPeople(url: URL) -> Single<PagedResponse<Person>> {
        return request(url: url)
    }
    
    func getFilms(url: URL) -> Single<PagedResponse<Film>> {
        return request(url: url)
    }
    
    func getPlanets(url: URL) -> Single<PagedResponse<Planet>> {
        return request(url: url)
    }
    
    func getSpecies(url: URL) -> Single<PagedResponse<Specie>> {
        return request(url: url)
    }
    
    func getVehicles(url: URL) -> Single<PagedResponse<Vehicle>> {
        return request(url: url)
    }
    
    func getStarships(url: URL) -> Single<PagedResponse<Starship>> {
        return request(url: url)
    }
}
