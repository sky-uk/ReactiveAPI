import Foundation
import Combine

extension URLSession {
    public func fetch(_ request: URLRequest, interceptors: [ReactiveAPIRequestInterceptor]? = nil) -> AnyPublisher<(request: URLRequest, response: HTTPURLResponse, data: Data), ReactiveAPIError> {
        var mutableRequest = request
        interceptors?.forEach { mutableRequest = $0.intercept(mutableRequest) }

        return self.dataTaskPublisher(for: mutableRequest)
            .tryMap { response in
                guard let httpResponse = response.response as? HTTPURLResponse
                else {
                    throw ReactiveAPIError.nonHttpResponse(response: response.response)
                }

                if httpResponse.statusCode < 200 || httpResponse.statusCode >= 300 {
                    throw ReactiveAPIError.httpError(request: mutableRequest, response: httpResponse, data: response.data)
                }

                return (mutableRequest, httpResponse, response.data)
            }
            .mapError { ReactiveAPIError.map($0) } // TODO: capire come gestire l'errore missingResponse
            .eraseToAnyPublisher()

    }
}

// Esempio di fetch con gestione singola degli errori
//func fetch(url: URL) -> AnyPublisher<Data, APIError> {
//    let request = URLRequest(url: url)
//
//    return URLSession.DataTaskPublisher(request: request, session: .shared)
//        .tryMap { data, response in
//            guard let httpResponse = response as? HTTPURLResponse else {
//                throw APIError.unknown
//            }
//            if (httpResponse.statusCode == 401) {
//                throw APIError.apiError(reason: "Unauthorized");
//            }
//            if (httpResponse.statusCode == 403) {
//                throw APIError.apiError(reason: "Resource forbidden");
//            }
//            if (httpResponse.statusCode == 404) {
//                throw APIError.apiError(reason: "Resource not found");
//            }
//            if (405..<500 ~= httpResponse.statusCode) {
//                throw APIError.apiError(reason: "client error");
//            }
//            if (500..<600 ~= httpResponse.statusCode) {
//                throw APIError.apiError(reason: "server error");
//            }
//            return data
//        }
//        .mapError { error in
//            // if it's our kind of error already, we can return it directly
//            if let error = error as? APIError {
//                return error
//            }
//            // if it is a TestExampleError, convert it into our new error type
//            if error is TestExampleError {
//                return APIError.parserError(reason: "Our example error")
//            }
//            // if it is a URLError, we can convert it into our more general error kind
//            if let urlerror = error as? URLError {
//                return APIError.networkError(from: urlerror)
//            }
//            // if all else fails, return the unknown error condition
//            return APIError.unknown
//        }
//        .eraseToAnyPublisher()
//}
