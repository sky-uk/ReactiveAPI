import XCTest
import RxSwift
import Combine
@testable import ReactiveAPIExt

class ReactiveFetcherTests: XCTestCase {
    func test_Init() {
        let service: (Int) -> Single<Void> = { _ in Single.just(()) }
        let fetcher = ReactiveFetcher(service: service)
        let subscription = fetcher.fetcher
            .subscribe(onNext: { XCTAssertEqual(0, $0 % 2) },
                       onError: { _ in XCTFail() },
                       onCompleted: { XCTFail() })

        fetcher.fetcher.onNext((2))
        fetcher.fetcher.onNext((4))
        fetcher.fetcher.onNext((6))
        subscription.dispose()
    }

    func test_Init_Combine() {
        let service: (Int) -> AnyPublisher<Void, Never> = { _ in Just(()).eraseToAnyPublisher() }
        let fetcher = ReactiveFetcher1(service: service)
        let subscription = fetcher.fetcher
            .sink(receiveCompletion: { _ in XCTFail() },
                  receiveValue: { XCTAssertEqual(0, $0 % 2) })
        fetcher.fetcher.send((2))
        fetcher.fetcher.send((4))
        fetcher.fetcher.send((6))
        subscription.cancel()
    }
}
