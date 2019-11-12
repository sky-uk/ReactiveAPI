import XCTest
import RxSwift
@testable import ReactiveAPI

class LoadingResultTests: XCTestCase {
    func test_InitLoading() {
        let result = LoadingResult<String>(false)
        XCTAssertNil(result.data)
        XCTAssertEqual(result.loading, false)
        let result2 = LoadingResult<String>(true)
        XCTAssertNil(result2.data)
        XCTAssertEqual(result2.loading, true)
    }

    func test_InitData() {
        let next = Event.next("data")
        let resultNext = LoadingResult<String>(next)
        XCTAssertEqual(resultNext.loading, false)
        XCTAssertEqual(resultNext.data?.event.element, "data")
        XCTAssertFalse(resultNext.data!.isCompleted)

        let completed = Event<String>.completed
        let resultCompleted = LoadingResult<String>(completed)
        XCTAssertEqual(resultCompleted.loading, false)
        XCTAssertNil(resultCompleted.data?.event.element)
        XCTAssertTrue(resultCompleted.data!.isCompleted)

        let error = Event<String>.error(ReactiveAPIError.unknown)
        let resultError = LoadingResult<String>(error)
        XCTAssertEqual(resultError.loading, false)
        XCTAssertNil(resultError.data?.event.element)
        XCTAssertFalse(resultError.data!.isCompleted)
        if let error = resultError.data?.error,
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
}
