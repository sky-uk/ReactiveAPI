import Foundation
import Combine
import CombineExt

protocol LoadingDataConvertible {
    associatedtype ElementType
    var data: SimpleEvent<ElementType>? { get }
    var loading: Bool { get }
}

struct LoadingResult<E>: LoadingDataConvertible {
    let data: SimpleEvent<E>?
    let loading: Bool

    init(_ loading: Bool) {
        self.data = nil
        self.loading = loading
    }

    init(_ data: SimpleEvent<E>) {
        self.data = data
        self.loading = false
    }
}

extension Publisher {
    func monitorLoading() -> AnyPublisher<LoadingResult<Output>, Never> {
        materialize()
            .map { data -> SimpleEvent<Output> in
                switch data {
                    case .value(let output):
                        return .next(output)
                    case .failure(let error):
                        return .error(error)
                    case .finished:
                        return .completed
                }
            }
            .map(LoadingResult.init)
            .prepend(LoadingResult(true))
            .eraseToAnyPublisher()
    }
}

extension Publisher where Output: LoadingDataConvertible {
    var events: AnyPublisher<SimpleEvent<Output.ElementType>, Self.Failure> {
        filter { !$0.loading }
            .map(\.data)
            .filter { $0 != nil }
            .map { $0! }
            .eraseToAnyPublisher()
    }
}
