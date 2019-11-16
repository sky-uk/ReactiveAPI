import XCTest
import RxSwift
import RxBlocking
import ReactiveAPI
@testable import ReactiveAPIExt

class LoadingResultTests: XCTestCase {
    private let next = LoadingResult<String>(Event.next("data"))
    private let completed = LoadingResult<String>(Event<String>.completed)
    private let error = LoadingResult<String>(Event<String>.error(ReactiveAPIError.unknown))
    private let loadingFalse = LoadingResult<String>(false)
    private let loadingTrue = LoadingResult<String>(true)

    func test_InitLoading() {
        XCTAssertNil(loadingFalse.data)
        XCTAssertEqual(loadingFalse.loading, false)

        XCTAssertNil(loadingTrue.data)
        XCTAssertEqual(loadingTrue.loading, true)
    }

    func test_InitData() {
        XCTAssertEqual(next.loading, false)
        XCTAssertEqual(next.data?.event.element, "data")
        XCTAssertFalse(next.data!.isCompleted)

        XCTAssertEqual(completed.loading, false)
        XCTAssertNil(completed.data?.event.element)
        XCTAssertTrue(completed.data!.isCompleted)

        XCTAssertEqual(error.loading, false)
        XCTAssertNil(error.data?.event.element)
        XCTAssertFalse(error.data!.isCompleted)
        if let error = error.data?.error,
            case ReactiveAPIError.unknown = error {
            XCTAssert(true)
        } else {
            XCTFail()
        }
    }

    func test_MonitorLoading_WhenCompleted_ReturnLoadingResult() {
        let count = Int.random(in: 1...10)
        let observable = Observable<String>.create { observer in
            Array(repeating: "event", count: count).enumerated()
                .forEach { observer.onNext("\($0)\($1)") }
            observer.onCompleted()
            return Disposables.create()
        }

        var results = try? observable
            .monitorLoading()
            .toBlocking()
            .toArray()

        XCTAssertNotNil(results)
        XCTAssertEqual(results?.count, 1 + count + 1)

        let first = results!.removeFirst()
        XCTAssertNil(first.data)
        XCTAssertEqual(first.loading, true)

        let last = results!.removeLast()
        XCTAssertEqual(last.loading, false)
        XCTAssertNil(last.data!.event.element)
        XCTAssertTrue(last.data!.isCompleted)

        results!.enumerated()
            .forEach { (index, result) in
                XCTAssertNotNil(result.data!.event.element)
                XCTAssert((result.data!.event.element!.contains("\(index)")))
        }
    }

    func test_MonitorLoading_WhenError_ReturnLoadingResult() {
        let observable = Observable<String>.create { observer in
            observer.onNext("event")
            observer.onError(ReactiveAPIError.unknown)
            return Disposables.create()
        }

        var results = try? observable
            .monitorLoading()
            .toBlocking()
            .toArray()

        XCTAssertNotNil(results)
        XCTAssertEqual(results?.count, 3)

        let first = results!.removeFirst()
        XCTAssertNil(first.data)
        XCTAssertEqual(first.loading, true)

        let last = results!.removeLast()
        XCTAssertEqual(last.loading, false)
        XCTAssertNil(last.data!.event.element)
        XCTAssertFalse(last.data!.isCompleted)
        if let error = last.data?.error,
            case ReactiveAPIError.unknown = error {
            XCTAssert(true)
        } else {
            XCTFail()
        }

        results!.enumerated()
            .forEach { (index, result) in
                XCTAssertNotNil(result.data!.event.element)
                XCTAssert((result.data!.event.element! == "event"))
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
            next,
        ]
        let results = try? Observable.from(events)
            .events
            .toBlocking()
            .toArray()

        XCTAssertNotNil(results)
        XCTAssertEqual(results?.count, 5)
    }
}
