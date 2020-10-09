## ReactiveAPI Demo
To see ReactiveAPI in action we created a complete http client.

Clone this repository, open `ReactiveAPIDemo` directory from your terminal and run:

Open `ReactiveAPIDemo` project from Xcode and hit `Run`.

![demo](https://user-images.githubusercontent.com/16792495/55287028-ffece280-53a3-11e9-9504-1dffa1f2316f.gif)

## Token Authenticated API Demo
Most of today REST APIs have a token authentication mechanism. We created a dedicated demo app, with a standalone node.js server to demostrate all the power of ReactiveAPI authentication handling. [Check it here](https://github.com/sky-uk/ReactiveAPI/tree/TokenAuthenticationDemo).

## What your network code will look like with ReactiveAPI
We highly suggest to create a `Network` group with two child groups: `APIs` and `Models`.

Example taken from ReactiveAPIDemo:
```
Network
 |--> APIs
   |--> StarWarsAPI.swift
 |--> Models
   |--> Film.swift
   |--> PagedResponse.swift
   |--> Person.swift
   |--> Root.swift
   |--> Planet.swift
   |--> Specie.swift
   |--> Vehicle.swift
   |--> Starship.swift
```
Every API will look like `StarWarsAPI.swift` (except the method parameters, which are specific to every API)
```swift
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
```
All the models, which represents the response payloads are `Codable` and `Hashable` structs, like `Film.swift`:
```swift
struct Film: Codable, Hashable {
    let title: String
    let episode_id: Int
    let opening_crawl: String
    let director: String
    let producer: String
    let release_date: String
    let species: [URL]
    let starships: [URL]
    let vehicles: [URL]
    let characters: [URL]
    let planets: [URL]
    let url: URL
}
```
This is how we suggest you to initialize an API you implemented using ReactiveAPI:
```swift
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    private static let baseURL = URL(string: "https://gotev.github.io/swapi-android")!

    var window: UIWindow?
    var client: StarWarsAPI!

    func setupReactiveAPI() {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.httpAdditionalHeaders = ["User-Agent": "ReactiveAPIDemo/\(appVersion)"]

        client = StarWarsAPI(session: URLSession(configuration: sessionConfig).rx,
                             decoder: JSONDecoder(),
                             baseUrl: AppDelegate.baseURL)
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        setupReactiveAPI()

        //your other initialization code. Simply inject client where you need it
    }
}
```
A call to an API (with an example data transformation) looks like this:
```swift
client.getRoot()
    .map { root in
        return [
            ViewModelData(title: "Films", subtitle: "All the films in the saga", url: root.films),
            ViewModelData(title: "People", subtitle: "Meet the characters", url: root.people),
            ViewModelData(title: "Planets", subtitle: "Discover new worlds", url: root.planets),
            ViewModelData(title: "Species", subtitle: "Extend your imagination", url: root.species),
            ViewModelData(title: "Vehicles", subtitle: "Take a ride", url: root.vehicles),
            ViewModelData(title: "Starships", subtitle: "Reach distant places fast", url: root.starships)
        ]
    }
    .asDriver(onErrorRecover: { error in
        print("Something bad happened: \(error)")
        return Driver.empty()
    })
    .drive(onNext: { data in
        // populate UI with the data
    })
    .disposed(by: disposeBag)
```
This is just a basic proof of concept of what you get. Of course, the library is capable of much more than this.
