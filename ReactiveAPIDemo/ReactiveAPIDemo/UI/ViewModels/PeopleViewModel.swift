import Foundation
import RxSwift

final class PeopleViewModel: ViewModel {
    override func apiCall() -> Single<[ViewModelData]> {
        return client.getPeople(url: url)
            .map { data in
                data.results.map {
                    ViewModelData(
                        title: $0.name,
                        subtitle: "Birth Year: \($0.birthYear)",
                        url: $0.url
                    )
                }
        }
    }
}

final class PersonViewModel: ViewModel {

    override func apiCall() -> Single<[ViewModelData]> {
        return client.getPerson(url: url)
            .map { data in
                return [
                    ViewModelData(title: data.name, subtitle: "Name", url: data.url),
                    ViewModelData(title: data.birthYear, subtitle: "Birth Year", url: data.url),
                    ViewModelData(title: data.gender, subtitle: "Gender", url: data.url),
                    ViewModelData(title: data.mass, subtitle: "Weight (Kg)", url: data.url),
                    ViewModelData(title: data.height, subtitle: "Height (cm)", url: data.url),
                    ViewModelData(title: data.hairColor, subtitle: "Hair Color", url: data.url),
                    ViewModelData(title: data.skinColor, subtitle: "Skin Color", url: data.url),
                    ViewModelData(title: data.eyeColor, subtitle: "Eye Color", url: data.url),
                    ViewModelData(title: "\(data.films.count)", subtitle: "Films", url: data.url),
                    ViewModelData(title: "\(data.vehicles.count)", subtitle: "Vehicles Possessed", url: data.url),
                    ViewModelData(title: "\(data.starships.count)", subtitle: "Starships Possessed", url: data.url)
                ]
        }
    }
}
