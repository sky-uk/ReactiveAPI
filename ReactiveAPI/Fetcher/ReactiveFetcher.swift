import Foundation
import RxSwift

public struct ReactiveFetcher<Input, Output> {
    public typealias Service = (Input) -> Single<Output>

    private let operation: Observable<LoadingResult<Output>>
    private let fetcher = PublishSubject<Input>()

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

    public func fetch(next input: Input) {
        fetcher.onNext(input)
    }
}
