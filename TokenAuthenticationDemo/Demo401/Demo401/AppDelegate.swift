import UIKit
import netfox_ios

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var services: Services!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.httpAdditionalHeaders = ["User-Agent": "Demo401/iOS/1.0.0"]

        let session = URLSession(configuration: sessionConfig).rx

        let decoder = JSONDecoder()
        let baseUrl = URL(string: "http://localhost:3000")!
        let tokenStorage = TokenStorage()

        let authClient = AuthClient(session: session, decoder: decoder, baseUrl: baseUrl)
        authClient.tokenStorage = tokenStorage

        let backendAPI = BackendAPI(session: session, decoder: decoder, baseUrl: baseUrl)
        backendAPI.authenticator = AuthClientAuthenticator(authClient: authClient)
        backendAPI.requestInterceptors += [AuthClientInterceptor(tokenStorage: tokenStorage)]

        services = Services(authClient: authClient, backendAPI: backendAPI)

        let mainViewController = ViewController()
        mainViewController.services = services

        NFX.sharedInstance().start()

        window = UIWindow()
        window?.backgroundColor = .white
        window?.rootViewController = mainViewController
        window?.makeKeyAndVisible()

        return true
    }

}

