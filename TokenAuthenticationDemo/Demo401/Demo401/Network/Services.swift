import Foundation

struct Services {
    let authClient: AuthClient
    let backendAPI: BackendAPI

    init(authClient: AuthClient, backendAPI: BackendAPI) {
        self.authClient = authClient
        self.backendAPI = backendAPI
    }
}
