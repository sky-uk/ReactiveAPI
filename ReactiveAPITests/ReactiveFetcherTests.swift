import XCTest
import ReactiveAPI
import RxSwift

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
}
