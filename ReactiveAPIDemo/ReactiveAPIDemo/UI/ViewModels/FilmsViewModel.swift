import Foundation
import RxSwift

class FilmsViewModel: ViewModel {
    override func apiCall() -> Single<[ViewModelData]> {
        return client.getFilms(url: url)
            .map { data in
                data.results
                    .sorted(by: { (a, b) -> Bool in
                        return a.episode_id < b.episode_id
                    })
                    .map {
                        ViewModelData(
                            title: $0.title,
                            subtitle: "Release date: \($0.release_date)",
                            url: $0.url
                        )
                }
        }
    }
}

class FilmViewModel: ViewModel {
    
    override func apiCall() -> Single<[ViewModelData]> {
        return client.getFilm(url: url)
            .map { data in
                return [
                    ViewModelData(title: data.title, subtitle: "Title", url: data.url),
                    ViewModelData(title: data.release_date, subtitle: "Release Date", url: data.url),
                    ViewModelData(title: "\(data.episode_id)", subtitle: "Episode ID", url: data.url),
                    ViewModelData(title: data.director, subtitle: "Director", url: data.url),
                    ViewModelData(title: data.producer, subtitle: "Producer", url: data.url),
                    ViewModelData(title: "\(data.planets.count)", subtitle: "Planets involved", url: data.url),
                    ViewModelData(title: "\(data.vehicles.count)", subtitle: "Vehicles involved", url: data.url),
                    ViewModelData(title: "\(data.starships.count)", subtitle: "Starships involved", url: data.url),
                    ViewModelData(title: "\(data.characters.count)", subtitle: "Characters involved", url: data.url),
                    ViewModelData(title: "\(data.species.count)", subtitle: "Species involved", url: data.url),
                ]
        }
    }
}
