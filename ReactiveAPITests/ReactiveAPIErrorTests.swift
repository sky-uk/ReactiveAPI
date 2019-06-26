import XCTest
import ReactiveAPI

class ReactiveAPIErrorTests: XCTestCase {
    private enum CodingKeys: String, CodingKey { case test }
    private static let context = DecodingError.Context(codingPath: [], debugDescription: "Value not found.")

    private let keyNotFound = DecodingError.keyNotFound(CodingKeys.test, ReactiveAPIErrorTests.context)
    private let typeMismatch = DecodingError.typeMismatch(ModelMock.self, ReactiveAPIErrorTests.context)
    private let dataCorrupted = DecodingError.dataCorrupted(ReactiveAPIErrorTests.context)

    private let urlComponentsError = ReactiveAPIError.URLComponentsError(Resources.url)
    private let httpError = ReactiveAPIError.httpError(response: Resources.httpUrlResponse(code: 500)!, data: Resources.data)

    func test_ErrorDescription() {
        XCTAssertNil(urlComponentsError.errorDescription)
        XCTAssertNil(httpError.errorDescription)
        let description = ReactiveAPIError.decodingError(dataCorrupted, data: Resources.data).errorDescription
        XCTAssertNotNil(description)
        XCTAssertEqual(description, dataCorrupted.localizedDescription)
    }

    func test_FailureReason() {
        XCTAssertNil(urlComponentsError.failureReason)
        XCTAssertNil(httpError.failureReason)

        let keyNotFoundReason = ReactiveAPIError.decodingError(keyNotFound, data: Resources.data).failureReason
        XCTAssertNotNil(keyNotFoundReason)
        XCTAssertEqual(keyNotFoundReason, "root.test: Not Found!")

        let typeMismatchReason = ReactiveAPIError.decodingError(typeMismatch, data: Resources.data).failureReason
        XCTAssertNotNil(typeMismatchReason)
        XCTAssertEqual(typeMismatchReason, "root: Value not found.")

        let dataCorruptedReason = ReactiveAPIError.decodingError(dataCorrupted, data: Resources.data).failureReason
        XCTAssertEqual(dataCorruptedReason, dataCorrupted.failureReason)
    }
}
