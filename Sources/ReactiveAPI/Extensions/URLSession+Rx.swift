import Foundation

extension URLSession {
    public func fetch(_ request: URLRequest, interceptors: [ReactiveAPIRequestInterceptor]? = nil) async throws -> (request: URLRequest, response: HTTPURLResponse, data: Data) {
        try await withCheckedThrowingContinuation { continuation in

            var mutableRequest = request
            interceptors?.forEach { mutableRequest = $0.intercept(mutableRequest) }

            let task = URLSession.shared.dataTask(with: mutableRequest) { data, response, error in
                guard let response = response, let data = data else {
                    continuation.resume(throwing: error ?? ReactiveAPIError.unknown)
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    continuation.resume(throwing: ReactiveAPIError.nonHttpResponse(response: response))
                    return
                }

                if httpResponse.statusCode < 200 || httpResponse.statusCode >= 300 {
                    continuation.resume(throwing: ReactiveAPIError.httpError(request: mutableRequest, response: httpResponse, data: data))
                    return
                }

                continuation.resume(returning: (request: mutableRequest, response: httpResponse, data: data))
            }

            task.resume()
        }
    }
}
