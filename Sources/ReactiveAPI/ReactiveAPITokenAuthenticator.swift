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
    private var currentToken1 = CurrentValueSubject<String?, ReactiveAPIError>(nil)
    private let tokenHeaderName: String
    private let getCurrentToken: () -> String?
    private let renewToken1: () -> AnyPublisher<String, ReactiveAPIError>
    private let shouldRenewToken: (URLRequest, HTTPURLResponse, Data?) -> Bool
    private let logger: ReactiveAPITokenAuthenticatorLogger?

    public init(tokenHeaderName: String,
                getCurrentToken: @escaping () -> String?,
                renewToken1: @escaping () -> AnyPublisher<String, ReactiveAPIError>,
                shouldRenewToken: @escaping(URLRequest, HTTPURLResponse, Data?) -> Bool = { _, _, _ in true },
                logger: ReactiveAPITokenAuthenticatorLogger? = nil) {
        self.tokenHeaderName = tokenHeaderName
        self.getCurrentToken = getCurrentToken
        self.renewToken1 = renewToken1
        self.shouldRenewToken = shouldRenewToken
        self.logger = logger
    }

    func requestWithNewToken1(session: URLSession,
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

    public func authenticate1(session: URLSession, request: URLRequest, response: HTTPURLResponse, data: Data?) -> AnyPublisher<Data, ReactiveAPIError>? {
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
            return requestWithNewToken1(session: session, request: request, newToken: actualToken)
        }

        if isRenewingToken {
            logger?.log(state: .waitingForTokenRenewWhichIsInProgress)

            return currentToken1
                .filter { $0 != nil }
                .map { $0! }
                .first()
                .flatMap { token -> AnyPublisher<Data, ReactiveAPIError> in
                    self.logger?.log(state: .finishedWaitingForTokenRenew)
                    return self.requestWithNewToken1(session: session, request: request, newToken: token)
                }
                .mapError { ReactiveAPIError.map($0) }
                .eraseToAnyPublisher()
        }

        logger?.log(state: .startedTokenRefresh)

        setNewToken1(token: nil, isRenewing: true)

        return renewToken1()
            .tryCatch { error -> AnyPublisher<String, ReactiveAPIError> in
                self.logger?.log(state: .tokenRenewError(error))
                self.setNewToken1(token: nil, isRenewing: false)
                let httpError = ReactiveAPIError.httpError(request: request, response: response, data: data ?? Data())
                throw httpError
            }
            .mapError { ReactiveAPIError.map($0) }
            .flatMap { newToken -> AnyPublisher<Data, ReactiveAPIError> in
                self.setNewToken1(token: newToken, isRenewing: false)
                self.logger?.log(state: .tokenRenewSucceeded)
                return self.requestWithNewToken1(session: session, request: request, newToken: newToken)
            }
            .mapError { ReactiveAPIError.map($0) }
            .eraseToAnyPublisher()
    }

    func setNewToken1(token: String?, isRenewing: Bool) {
        if currentToken1.value == nil && token != nil || currentToken1.value != nil && token != nil {
            isRenewingToken = false
        } else {
            isRenewingToken = isRenewing
        }
        currentToken1.send(token)
    }
}
