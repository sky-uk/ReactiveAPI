import Foundation
import RxSwift

protocol LoadingDataConvertible {
    associatedtype ElementType
    var data: Event<ElementType>? { get }
    var loading: Bool { get }
}

struct LoadingResult<E>: LoadingDataConvertible {
    let data: Event<E>?
    let loading: Bool

    init(_ loading: Bool) {
        self.data = nil
        self.loading = loading
    }

    init(_ data: Event<E>) {
        self.data = data
        self.loading = false
    }
}

extension ObservableType {
    func monitorLoading() -> Observable<LoadingResult<Element>> {
        materialize()
            .map(LoadingResult.init)
            .startWith(LoadingResult(true))
    }
}

extension ObservableType where Element: LoadingDataConvertible {
    var events: Observable<Event<Element.ElementType>> {
        filter { !$0.loading }
            .map { $0.data }
            .filter { $0 != nil }
            .map { $0! }
    }
}
