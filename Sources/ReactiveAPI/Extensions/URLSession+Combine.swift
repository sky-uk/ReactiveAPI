import Foundation
import Combine

extension URLSession {
    public func fetch(_ request: URLRequest, interceptors: [ReactiveAPIRequestInterceptor]? = nil) -> AnyPublisher<(request: URLRequest, response: HTTPURLResponse, data: Data), ReactiveAPIError> {
        var mutableRequest = request
        interceptors?.forEach { mutableRequest = $0.intercept(mutableRequest) }

        return self.dataTaskPublisher(for: mutableRequest)
            .tryMap { response in
                // 'guard' order matters
                guard let httpResponse = response.response as? HTTPURLResponse else {
                    throw ReactiveAPIError.nonHttpResponse(response: response.response)
                }

                if httpResponse.statusCode < 200 || httpResponse.statusCode >= 300 {
                    throw ReactiveAPIError.httpError(request: mutableRequest, response: httpResponse, data: response.data)
                }

                guard !response.data.isEmpty else {
                    throw ReactiveAPIError.missingResponseData(request: mutableRequest)
                }

                return (mutableRequest, httpResponse, response.data)
            }
            .mapError { ReactiveAPIError.map($0) }
            .eraseToAnyPublisher()

    }
}
