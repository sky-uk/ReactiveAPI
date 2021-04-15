import Foundation
import Combine
import CombineExt

protocol LoadingDataConvertible1 {
    associatedtype ElementType
    var data: SkyEvent<ElementType>? { get } //Event<ElementType, Error>? { get }
    var loading: Bool { get }
}

struct LoadingResult1<E>: LoadingDataConvertible1 {
    let data: SkyEvent<E>? //Event<E, Error>?
    let loading: Bool

    init(_ loading: Bool) {
        self.data = nil
        self.loading = loading
    }

    init(_ data: SkyEvent<E>) { //Event<E, Error>) {
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
//
//extension SkyEvent: Equatable where Element: Equatable {
//    static public func == (lhs: Self, rhs: Self) -> Bool {
//        switch (lhs, rhs) {
//            case (.completed, .completed):
//                return true
//            case (.next(let outputLhs), .next(let outputRhs)):
//                return outputLhs == outputRhs
//            case (.error(let errorLhs), .error(let errorRhs)):
//                return errorLhs.localizedDescription == errorRhs.localizedDescription
//            default:
//                return false
//        }
//    }
//}

public enum SkyEvent<Element> {

    /// Next element is produced.
    case next(Element)

    /// Sequence terminated with an error.
    case error(Error)

    /// Sequence completed successfully.
    case completed
}
