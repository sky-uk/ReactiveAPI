import XCTest
import ReactiveAPI

class EncodableTests: XCTestCase {
    private struct MockEncodable: Encodable {
        let name: String
        let id: Double
    }

    func test_Dictionary_WhenDataIsValid_RetursDictionary() {
        let encodable = MockEncodable(name: "Patrick",
                                      id: 5)
        let result = encodable.dictionary
        XCTAssertNotNil(result)
        XCTAssertEqual(result?["name"] as? String, "Patrick")
        XCTAssertEqual(result?["id"] as? Int, 5)
    }

    func test_Dictionary_WhenDataIsNotValid_RetursNil() {
        let encodable = MockEncodable(name: "Infinity",
                                      id: .infinity)
        let result = encodable.dictionary
        XCTAssertNil(result)
    }
}
