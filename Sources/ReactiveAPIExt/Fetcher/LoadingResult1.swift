import Foundation
import Combine
import CombineExt

protocol LoadingDataConvertible1 {
    associatedtype ElementType
    var data: SkyEvent<ElementType>? { get }
    var loading: Bool { get }
}

struct LoadingResult1<E>: LoadingDataConvertible1 {
    let data: SkyEvent<E>?
    let loading: Bool

    init(_ loading: Bool) {
        self.data = nil
        self.loading = loading
    }

    init(_ data: SkyEvent<E>) {
        self.data = data
        self.loading = false
    }
}

extension Publisher {
    func monitorLoading() -> AnyPublisher<LoadingResult1<Output>, Never> {
        materialize()
            .map { data -> SkyEvent<Output> in
                switch data {
                    case .value(let output):
                        return .next(output)
                    case .failure(let error):
                        return .error(error)
                    case .finished:
                        return .completed
                }
            }
            .map(LoadingResult1.init)
            .prepend(LoadingResult1(true))
            .eraseToAnyPublisher()
    }
}

extension Publisher where Output: LoadingDataConvertible1 {
    var events: AnyPublisher<SkyEvent<Output.ElementType>, Self.Failure> {
        filter { !$0.loading }
            .map(\.data)
            .filter { $0 != nil }
            .map { $0! }
            .eraseToAnyPublisher()
    }
}

public enum SkyEvent<Element> {

    /// Next element is produced.
    case next(Element)

    /// Sequence terminated with an error.
    case error(Error)

    /// Sequence completed successfully.
    case completed
}

extension SkyEvent {

    /// Is `completed` or `error` event.
    public var isStopEvent: Bool {
        switch self {
            case .completed, .error(_):
                return true
            default:
                return false
        }
    }

    /// If `next` event, returns element value.
    public var element: Element? {
        switch self {
            case .next(let element):
                return element
            default:
                return nil
        }
    }

    /// If `error` event, returns error.
    public var error: Error? {
        switch self {
            case .error(let error):
                return error
            default:
                return nil
        }
    }

    /// If `completed` event, returns `true`.
    public var isCompleted: Bool {
        switch self {
            case .completed:
                return true
            default:
                return false
        }
    }
}
