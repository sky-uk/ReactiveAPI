import Foundation
import RxSwift
import Combine

public struct ReactiveFetcher<Input, Output> {
    public typealias Service = (Input) -> Single<Output>
    public let fetcher = PublishSubject<Input>()

    private let operation: Observable<LoadingResult<Output>>

    public init(service: @escaping Service) {
        operation = fetcher
            .flatMapLatest { service($0).asObservable().monitorLoading() }
            .share()
    }

    public var output: Observable<Output> {
        operation.events
            .filter { $0.event.element != nil }
            .map { $0.event.element! }
    }

    public var error: Observable<Error> {
        operation.events
            .filter { $0.event.error != nil }
            .map { $0.event.error! }
    }

    public var isLoading: Observable<Bool> {
        operation
            .map { $0.loading }
            .startWith(false)
            .distinctUntilChanged()
    }

    public var isCompleted: Observable<Void> {
        operation.events
            .filter { $0.event.isCompleted }
            .map { _ in }
    }
}

public class ReactiveFetcher1<Input, Output> {
    public typealias Service = (Input) -> AnyPublisher<Output, Never>
    public let fetcher = PassthroughSubject<Input, Never>()

    private let operation: AnyPublisher<LoadingResult1<Output>, Never>

    public init(service: @escaping Service) {
        operation = fetcher
            .flatMapLatest { service($0).monitorLoading() }
            .eraseToAnyPublisher()
    }

    public var output: AnyPublisher<Output, Never> {
        operation.events
            .map {
                switch $0 {
                    case .next(let output):
                        return output
                    default:
                        return nil
                }
            }
            .filter { $0 != nil }
            .map { $0! }
            .eraseToAnyPublisher()
    }

    public var error: AnyPublisher<Error, Never> {
        operation.events
            .map {
                switch $0 {
                    case .error(let error):
                        return error
                    default:
                        return nil
                }
            }
            .filter { $0 != nil }
            .map { $0! }
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

    public var isCompleted: AnyPublisher<Bool, Never> {
        operation.events
            .map {
                switch $0 {
                    case .completed:
                        return true
                    default:
                        return false
                }
            }
            .filter { $0 == true }
            .eraseToAnyPublisher()
    }
}
