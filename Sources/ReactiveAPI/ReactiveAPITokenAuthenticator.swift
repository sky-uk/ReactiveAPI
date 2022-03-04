import Foundation
import RxCocoa

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
    private var currentToken: String? = nil
    private let tokenHeaderName: String
    private let getCurrentToken: () -> String?
    private let renewToken: () async throws -> String
    private let shouldRenewToken: (URLRequest, HTTPURLResponse, Data?) -> Bool
    private let logger: ReactiveAPITokenAuthenticatorLogger?

    public init(tokenHeaderName: String,
                getCurrentToken: @escaping () -> String?,
                renewToken: @escaping () async throws -> String,
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
                             newToken: String) async throws -> Data {
        logger?.log(state: .retryingRequestWithNewToken)

        var newRequest = request
        newRequest.setValue(newToken, forHTTPHeaderField: tokenHeaderName)
        return try await session.fetch(newRequest).data
    }

    public func authenticate(session: URLSession, request: URLRequest, response: HTTPURLResponse, data: Data?) async throws-> Data? {
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
            return try await requestWithNewToken(session: session, request: request, newToken: actualToken)
        }

        if isRenewingToken {
            logger?.log(state: .waitingForTokenRenewWhichIsInProgress)

            async let token = currentToken ?? "" // TODO
            self.logger?.log(state: .finishedWaitingForTokenRenew)
            return try await self.requestWithNewToken(session: session, request: request, newToken: token)
        }

        logger?.log(state: .startedTokenRefresh)

        setNewToken(token: nil, isRenewing: true)

        do {
            async let newToken = renewToken()
            self.setNewToken(token: try await newToken, isRenewing: false)
            self.logger?.log(state: .tokenRenewSucceeded)
            return try await self.requestWithNewToken(session: session, request: request, newToken: await newToken)
        } catch (let error) {
            self.logger?.log(state: .tokenRenewError(error))
            self.setNewToken(token: nil, isRenewing: false)
            let httpError = ReactiveAPIError.httpError(request: request, response: response, data: data ?? Data())
            throw httpError
        }
    }

    func setNewToken(token: String?, isRenewing: Bool) {
        if currentToken == nil && token != nil || currentToken != nil && token != nil {
            isRenewingToken = false
        } else {
            isRenewingToken = isRenewing
        }
        currentToken = token
    }
}
