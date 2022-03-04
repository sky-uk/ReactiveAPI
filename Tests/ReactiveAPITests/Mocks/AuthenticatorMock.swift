import Foundation
import ReactiveAPI

struct AuthenticatorMock: ReactiveAPIAuthenticator {
    let code: Int

    func authenticate(session: URLSession,
                      request: URLRequest,
                      response: HTTPURLResponse,
                      data: Data?) async throws-> Data? {
        guard response.statusCode == code
            else { return nil }

        return Resources.data
    }
}
