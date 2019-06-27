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

    func getPerson(url: URL) -> Single<Person> {
        return request(url: url)
    }

    func getFilms(url: URL) -> Single<PagedResponse<Film>> {
        return request(url: url)
    }

    func getFilm(url: URL) -> Single<Film> {
        return request(url: url)
    }

    func getPlanets(url: URL) -> Single<PagedResponse<Planet>> {
        return request(url: url)
    }

    func getPlanet(url: URL) -> Single<Planet> {
        return request(url: url)
    }

    func getSpecies(url: URL) -> Single<PagedResponse<Specie>> {
        return request(url: url)
    }

    func getSpecie(url: URL) -> Single<Specie> {
        return request(url: url)
    }

    func getVehicles(url: URL) -> Single<PagedResponse<Vehicle>> {
        return request(url: url)
    }

    func getVehicle(url: URL) -> Single<Vehicle> {
        return request(url: url)
    }

    func getStarships(url: URL) -> Single<PagedResponse<Starship>> {
        return request(url: url)
    }

    func getStarship(url: URL) -> Single<Starship> {
        return request(url: url)
    }
}
