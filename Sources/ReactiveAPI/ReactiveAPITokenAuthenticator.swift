import Foundation
import Combine

public enum ReactiveAPITokenAuthenticatorState {
    case invoked
    case skippedHandlingBecauseOfMissingToken
    case skippedHandlingBecauseOfWrongErrorCode(_ code: Int)
    case skippedHandlingBecauseOfBusinessLogic
    case waitingForTokenRenewWhichIsInProgress
    case injectingExistingToken
    case finishedWaitingForTokenRenew
    case retryingRequestWithNewToken
    case startedTokenRefresh
    case tokenRenewSucceeded
    case tokenRenewError(_ error: Error)
}

public protocol ReactiveAPITokenAuthenticatorLogger {
    func log(state: ReactiveAPITokenAuthenticatorState)
}

public class ReactiveAPITokenAuthenticator: ReactiveAPIAuthenticator {

    private var isRenewingToken = false
    private var currentToken = CurrentValueSubject<String?, ReactiveAPIError>(nil)
    private let tokenHeaderName: String
    private let getCurrentToken: () -> String?
    private let renewToken: () -> AnyPublisher<String, ReactiveAPIError>
    private let shouldRenewToken: (URLRequest, HTTPURLResponse, Data?) -> Bool
    private let logger: ReactiveAPITokenAuthenticatorLogger?

    public init(tokenHeaderName: String,
                getCurrentToken: @escaping () -> String?,
                renewToken: @escaping () -> AnyPublisher<String, ReactiveAPIError>,
                shouldRenewToken: @escaping(URLRequest, HTTPURLResponse, Data?) -> Bool = { _, _, _ in true },
                logger: ReactiveAPITokenAuthenticatorLogger? = nil) {
        self.tokenHeaderName = tokenHeaderName
        self.getCurrentToken = getCurrentToken
        self.renewToken = renewToken
        self.shouldRenewToken = shouldRenewToken
        self.logger = logger
    }

    func requestWithNewToken(session: URLSession,
                             request: URLRequest,
                             newToken: String) -> AnyPublisher<Data, ReactiveAPIError> {
        logger?.log(state: .retryingRequestWithNewToken)

        var newRequest = request
        newRequest.setValue(newToken, forHTTPHeaderField: tokenHeaderName)
        return session.fetch(newRequest)
            .map(\.data)
            .mapError { ReactiveAPIError.map($0) }
            .eraseToAnyPublisher()
    }

    public func authenticate(session: URLSession, request: URLRequest, response: HTTPURLResponse, data: Data?) -> AnyPublisher<Data, ReactiveAPIError>? {
        logger?.log(state: .invoked)

        guard response.statusCode == 401,
              let actualToken = getCurrentToken() else {
            response.statusCode == 401
                ? logger?.log(state: .skippedHandlingBecauseOfMissingToken)
                : logger?.log(state: .skippedHandlingBecauseOfWrongErrorCode(response.statusCode))

            return nil
        }

        if !shouldRenewToken(request, response, data) {
            logger?.log(state: .skippedHandlingBecauseOfBusinessLogic)
            return nil
        }

        let failedRequestToken = request.value(forHTTPHeaderField: tokenHeaderName)

        if failedRequestToken == nil || failedRequestToken != actualToken {
            logger?.log(state: .injectingExistingToken)
            return requestWithNewToken(session: session, request: request, newToken: actualToken)
        }

        if isRenewingToken {
            logger?.log(state: .waitingForTokenRenewWhichIsInProgress)

            return currentToken
                .filter { $0 != nil }
                .map { $0! }
                .first()
                .flatMap { token -> AnyPublisher<Data, ReactiveAPIError> in
                    self.logger?.log(state: .finishedWaitingForTokenRenew)
                    return self.requestWithNewToken(session: session, request: request, newToken: token)
                }
                .mapError { ReactiveAPIError.map($0) }
                .eraseToAnyPublisher()
        }

        logger?.log(state: .startedTokenRefresh)

        setNewToken(token: nil, isRenewing: true)

        return renewToken()
            .tryCatch { error -> AnyPublisher<String, ReactiveAPIError> in
                self.logger?.log(state: .tokenRenewError(error))
                self.setNewToken(token: nil, isRenewing: false)
                let httpError = ReactiveAPIError.httpError(request: request, response: response, data: data ?? Data())
                throw httpError
            }
            .mapError { ReactiveAPIError.map($0) }
            .flatMap { newToken -> AnyPublisher<Data, ReactiveAPIError> in
                self.setNewToken(token: newToken, isRenewing: false)
                self.logger?.log(state: .tokenRenewSucceeded)
                return self.requestWithNewToken(session: session, request: request, newToken: newToken)
            }
            .mapError { ReactiveAPIError.map($0) }
            .eraseToAnyPublisher()
    }

    func setNewToken(token: String?, isRenewing: Bool) {
        if currentToken.value == nil && token != nil || currentToken.value != nil && token != nil {
            isRenewingToken = false
        } else {
            isRenewingToken = isRenewing
        }
        currentToken.send(token)
    }
}
