import XCTest
import Combine
import CombineExt
@testable import ReactiveAPIExt

private enum LoadingResultTestsError: Error {
    case unknown
}

class LoadingResultTests: XCTestCase {
    private let next = LoadingResult<String>(SkyEvent.next("data"))
    private let completed = LoadingResult<String>(SkyEvent<String>.completed)
    private let error = LoadingResult<String>(SkyEvent<String>.error(LoadingResultTestsError.unknown))
    private let loadingFalse = LoadingResult<String>(false)
    private let loadingTrue = LoadingResult<String>(true)

    func test_InitLoading() {
        XCTAssertNil(loadingFalse.data)
        XCTAssertEqual(loadingFalse.loading, false)

        XCTAssertNil(loadingTrue.data)
        XCTAssertEqual(loadingTrue.loading, true)
    }

    func test_InitData() throws {
        XCTAssertEqual(next.loading, false)
        let dataNext = try XCTUnwrap(next.data)
        XCTAssertEqual(dataNext.element, "data")
        XCTAssertFalse(dataNext.isCompleted)

        XCTAssertEqual(completed.loading, false)
        let dataCompleted = try XCTUnwrap(completed.data)
        XCTAssertNil(dataCompleted.element)
        XCTAssertTrue(dataCompleted.isCompleted)

        XCTAssertEqual(error.loading, false)
        let dataError = try XCTUnwrap(error.data)
        let error = try XCTUnwrap(dataError.error)
        XCTAssertNil(dataError.element)
        XCTAssertFalse(dataError.isCompleted)
        XCTAssert(error is LoadingResultTestsError)
        if case LoadingResultTestsError.unknown = error { XCTAssert(true) } else { XCTFail() }
    }

    func test_MonitorLoading_WhenCompleted_ReturnLoadingResult() throws {
        let count = Int.random(in: 1...10)
        let publisher = AnyPublisher<String, Never>.create { subscriber in
            Array(repeating: "event", count: count).enumerated()
                .forEach { subscriber.send("\($0.offset)\($0.element)") }
            subscriber.send(completion: .finished)
            return AnyCancellable {}
        }

        let sequence = try? publisher
            .monitorLoading()
            .waitForCompletion()

        var results = try XCTUnwrap(sequence)
        XCTAssertEqual(results.count, 1 + count + 1)

        let first = results.removeFirst()
        XCTAssertNil(first.data)
        XCTAssertEqual(first.loading, true)

        let last = results.removeLast()
        XCTAssertEqual(last.loading, false)
        XCTAssertNil(last.data!.element)
        XCTAssertTrue(last.data!.isCompleted)

        results.enumerated()
            .forEach { (index, result) in
                XCTAssertNotNil(result.data!.element)
                XCTAssert((result.data!.element!.contains("\(index)")))
            }
    }

    func test_MonitorLoading_WhenError_ReturnLoadingResult() throws {
        let publisher = AnyPublisher<String, Error>.create { subscriber in
            subscriber.send("event")
            subscriber.send(completion: .failure(LoadingResultTestsError.unknown))
            return AnyCancellable {}
        }

        let sequence = try? publisher
            .monitorLoading()
            .waitForCompletion()

        var results = try XCTUnwrap(sequence)
        XCTAssertEqual(results.count, 3)

        let first = results.removeFirst()
        XCTAssertNil(first.data)
        XCTAssertEqual(first.loading, true)

        let last = results.removeLast()
        XCTAssertEqual(last.loading, false)
        XCTAssertNil(last.data!.element)
        XCTAssertFalse(last.data!.isCompleted)
        if let error = last.data?.error,
           case LoadingResultTestsError.unknown = error {
            XCTAssert(true)
        } else {
            XCTFail()
        }

        results.enumerated()
            .forEach { (_, result) in
                XCTAssertNotNil(result.data!.element)
                XCTAssert((result.data!.element! == "event"))
            }
    }

    func test_Events_ReturnFiltered() {
        let events = [
            loadingTrue,
            next,
            loadingFalse,
            loadingFalse,
            completed,
            next,
            error,
            loadingTrue,
            next
        ]

        let results = try? awaitCompletion(of: events.publisher.events)

        XCTAssertNotNil(results)
        XCTAssertEqual(results?.count, 5)
    }
}
