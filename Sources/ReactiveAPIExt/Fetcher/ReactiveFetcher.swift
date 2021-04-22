import Foundation
import Combine

public class ReactiveFetcher<Input, Output> {
    public typealias Service = (Input) -> AnyPublisher<Output, Never>
    public let fetcher = PassthroughSubject<Input, Never>()

    private let operation: AnyPublisher<LoadingResult<Output>, Never>

    public init(service: @escaping Service) {
        operation = fetcher
            .flatMapLatest { service($0).monitorLoading() }
            .eraseToAnyPublisher()
    }

    public var output: AnyPublisher<Output, Never> {
        operation.events
            .filter { $0.element != nil }
            .map { $0.element! }
            .eraseToAnyPublisher()
    }

    public var error: AnyPublisher<Error, Never> {
        operation.events
            .filter { $0.error != nil }
            .map { $0.error! }
            .eraseToAnyPublisher()
    }

    public var isLoading: AnyPublisher<Bool, Never> {
        operation
            .tryMap { $0.loading }
            .replaceError(with: false)
            .prepend(false)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    public var isCompleted: AnyPublisher<Void, Never> {
        operation.events
            .filter { $0.isCompleted }
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}
