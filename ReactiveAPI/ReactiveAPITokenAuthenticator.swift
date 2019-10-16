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
    private let tokenHeaderName: String
    private let getCurrentToken: () -> String?
    private let renewToken: () -> Single<String>
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

    private func requestWithNewToken(session: Reactive<URLSession>, request: URLRequest, newToken: String) -> Single<Data> {
        logger?.log(state: .retryingRequestWithNewToken)

        var newRequest = request
        newRequest.setValue(newToken, forHTTPHeaderField: tokenHeaderName)
        return session.response(newRequest)
            .map { $0.data }
            .asSingle()
    }

    public func authenticate(session: Reactive<URLSession>, request: URLRequest, response: HTTPURLResponse, data: Data?) -> Single<Data>? {
        logger?.log(state: .invoked)

        guard response.statusCode == 401, let _ = getCurrentToken() else {
            response.statusCode == 401
                ? logger?.log(state: .skippedHandlingBecauseOfMissingToken)
                : logger?.log(state: .skippedHandlingBecauseOfWrongErrorCode(response.statusCode))

            return nil
        }

        if (isRenewingToken) {
            logger?.log(state: .waitingForTokenRenewWhichIsInProgress)

            return currentToken
                .filter { $0 != nil }.map { $0! }
                .take(1)
                .asSingle()
                .flatMap { token in
                    self.logger?.log(state: .finishedWaitingForTokenRenew)
                    return self.requestWithNewToken(session: session, request: request, newToken: token)
            }
        }

        logger?.log(state: .startedTokenRefresh)

        isRenewingToken = true
        currentToken.accept(nil)

        return renewToken()
            .flatMap { newToken in
                self.isRenewingToken = false
                self.currentToken.accept(newToken)
                self.logger?.log(state: .tokenRenewSucceeded)

                return self.requestWithNewToken(session: session, request: request, newToken: newToken)
            }.catchError { error in
                self.logger?.log(state: .tokenRenewError(error))
                self.isRenewingToken = false
                return Single.error(error)
        }
    }
}
