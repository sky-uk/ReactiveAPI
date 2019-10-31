import Foundation
import RxCocoa
import RxSwift

public enum ReactiveAPITokenAuthenticatorState {
    case invoked
    case skippedHandlingBecauseOfMissingToken
    case skippedHandlingBecauseOfWrongErrorCode(_ code: Int)
    case waitingForTokenRenewWhichIsInProgress
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
    private let currentToken = BehaviorRelay<String?>(value: nil)
    let tokenHeaderName: String
    let getCurrentToken: () -> String?
    let renewToken: () -> Single<String>
    private let logger: ReactiveAPITokenAuthenticatorLogger?

    public init(tokenHeaderName: String,
                getCurrentToken: @escaping () -> String?,
                renewToken: @escaping () -> Single<String>,
                logger: ReactiveAPITokenAuthenticatorLogger? = nil) {
        self.tokenHeaderName = tokenHeaderName
        self.getCurrentToken = getCurrentToken
        self.renewToken = renewToken
        self.logger = logger
    }

    func requestWithNewToken(session: Reactive<URLSession>,
                                      request: URLRequest,
                                      newToken: String) -> Single<Data> {
        logger?.log(state: .retryingRequestWithNewToken)

        var newRequest = request
        newRequest.setValue(newToken, forHTTPHeaderField: tokenHeaderName)
        return session.fetch(newRequest)
            .map { $0.data }
            .asSingle()
    }

    public func authenticate(session: Reactive<URLSession>, request: URLRequest, response: HTTPURLResponse, data: Data?) -> Single<Data>? {
        logger?.log(state: .invoked)

        guard response.statusCode == 401,
            let _ = getCurrentToken() else {
            response.statusCode == 401
                ? logger?.log(state: .skippedHandlingBecauseOfMissingToken)
                : logger?.log(state: .skippedHandlingBecauseOfWrongErrorCode(response.statusCode))

            return nil
        }

        if (isRenewingToken) {
            logger?.log(state: .waitingForTokenRenewWhichIsInProgress)

            return currentToken
                .filter { $0 != nil }
                .map { $0! }
                .take(1)
                .asSingle()
                .flatMap { token in
                    self.logger?.log(state: .finishedWaitingForTokenRenew)
                    return self.requestWithNewToken(session: session, request: request, newToken: token)
            }
        }

        logger?.log(state: .startedTokenRefresh)

        setNewToken(token: nil, isRenewing: true)

        return renewToken()
            .flatMap { newToken in
                self.setNewToken(token: newToken, isRenewing: false)
                self.logger?.log(state: .tokenRenewSucceeded)

                return self.requestWithNewToken(session: session, request: request, newToken: newToken)
            }.catchError { error in
                self.logger?.log(state: .tokenRenewError(error))
                self.setNewToken(token: nil, isRenewing: false)
                return Single.error(error)
        }
    }

    func setNewToken(token: String?, isRenewing: Bool) {
        if currentToken.value == nil && token != nil || currentToken.value != nil && token != nil {
            isRenewingToken = false
        } else {
            isRenewingToken = isRenewing
        }
        currentToken.accept(token)
    }
}
