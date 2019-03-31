import Foundation
import RxSwift

class SpeciesViewModel: ViewModel {
    override func apiCall() -> Single<[ViewModelData]> {
        return client.getSpecies(url: url)
            .map { data in
                data.results.map {
                    ViewModelData(
                        title: $0.name,
                        subtitle: "Average height: \($0.average_height) cm",
                        url: $0.url
                    )
                }
        }
    }
}

class SpecieViewModel: ViewModel {
    override func apiCall() -> Single<[ViewModelData]> {
        return client.getSpecie(url: url)
            .map { data in
                return [
                    ViewModelData(title: data.name, subtitle: "Name", url: data.url),
                    ViewModelData(title: data.language, subtitle: "Language", url: data.url),
                    ViewModelData(title: data.classification, subtitle: "Classification", url: data.url),
                    ViewModelData(title: data.designation, subtitle: "Designation", url: data.url),
                    ViewModelData(title: data.average_height, subtitle: "Average Height (cm)", url: data.url),
                    ViewModelData(title: data.average_lifespan, subtitle: "Average Lifespan (years)", url: data.url),
                    ViewModelData(title: data.skin_colors, subtitle: "Skin colors", url: data.url),
                    ViewModelData(title: data.eye_colors, subtitle: "Eye Colors", url: data.url),
                    ViewModelData(title: data.hair_colors, subtitle: "Hair Colors", url: data.url),
                    ViewModelData(title: "\(data.people.count)", subtitle: "Known People", url: data.url),
                    ViewModelData(title: "\(data.films.count)", subtitle: "Films", url: data.url)
                ]
        }
    }
}
