import XCTest
import Combine
@testable import ReactiveAPIExt

class ReactiveFetcherTests: XCTestCase {
    func test_Init() {
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
