import UIKit
import RxSwift
import ReactiveAPI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    private static let baseURL = URL(string: "https://swapi.co/api/")!

    var window: UIWindow?
    var navigationController: UINavigationController?
    var client: StarWarsAPI!

    func setupReactiveAPI() {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.httpAdditionalHeaders = ["User-Agent": "ReactiveAPIDemo/\(appVersion)"]

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        client = StarWarsAPI(session: URLSession(configuration: sessionConfig).rx,
                             decoder: decoder,
                             baseUrl: AppDelegate.baseURL)
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        setupReactiveAPI()

        let viewController = ListController(style: .grouped)
        viewController.title = "Main Menu"
        viewController.viewModelFactory = RootViewModelFactory(client: client)
        viewController.viewModel = RootViewModel(client: client, url: AppDelegate.baseURL)

        navigationController = UINavigationController(rootViewController: viewController)

        window = UIWindow()
        window?.backgroundColor = UIColor.white
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()

        return true
    }

}
