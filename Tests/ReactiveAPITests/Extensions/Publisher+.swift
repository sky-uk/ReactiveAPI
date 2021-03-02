import XCTest
import Combine

extension Publisher {
    func waitForCompletion(timeout: TimeInterval = 1.0) throws -> [Output] {
        let expectation = XCTestExpectation(description: "wait for completion")
        var completion: Subscribers.Completion<Failure>?
        var output = [Output]()

        let subscription = self.collect()
            .sink(receiveCompletion: { receiveCompletion in
                completion = receiveCompletion
                expectation.fulfill()
            }, receiveValue: { value in
                output = value
            })

        XCTWaiter().wait(for: [expectation], timeout: timeout)
        subscription.cancel()

        switch try XCTUnwrap(completion) {
            case let .failure(error):
                throw error
            case .finished:
                return output
        }
    }
}
