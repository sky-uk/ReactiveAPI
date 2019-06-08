import XCTest
import RxSwift
import RxBlocking
import RxCocoa
@testable import ReactiveAPI

class RxDataRequestTests: XCTestCase {
    private let json = """
        [ { "beautiful": "json" } ]
        """

    func test_RxDataRequest() {
        let session = URLSessionMock.create(json)
        let api = JSONReactiveAPI(session: session.rx,
                                  decoder: JSONDecoder(),
                                  baseUrl: Resources.url)

        do {
            let response = try api.rxDataRequest(URLRequest(url: Resources.url))
                .toBlocking()
                .single()

            XCTAssertNotNil(response)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
