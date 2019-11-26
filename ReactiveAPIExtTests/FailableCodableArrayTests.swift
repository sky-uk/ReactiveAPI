import XCTest
@testable import ReactiveAPIExt

final class FailableCodableArrayTests: XCTestCase {
    struct Root: Codable, Hashable {
        let items: FailableCodableArray<SUT>
    }

    struct SUT: Codable, Hashable {
        enum Foobar: String, Codable {
            case foo, bar
        }
        let title: String
        let foobar: Foobar
        let url: URL
    }

    func test_Decode() {
        // GIVEN
        let string = """
        {
            "items": [
                {"title": "A", "foobar": "foo", "url": "https://sky.it"},
                {"title": "A", "foobar": "foo", "url": "https://sky.it/with space"},
                {"title": "A", "foobar": "foobar", "url": "https://sky.it"},
                {"foobar": "foo", "url": "https://sky.it"}
            ]
        }
        """

        // WHEN
        let sut = try! JSONDecoder().decode(Root.self, from: string.data(using: .utf8)!)

        // THEN
        XCTAssertEqual(sut.items.elements.count, 1)
    }

    func test_Encode() {
        // GIVEN
        let element = SUT(title: "A", foobar: .foo, url: URL(string: "https://sky.it")!)
        let root = Root(items: FailableCodableArray<SUT>(elements: [element]) )

        // WHEN
        let encode = try! JSONEncoder().encode(root)
        let sut = try! JSONDecoder().decode(Root.self, from: encode)

        //THEN
        XCTAssertEqual(sut.items.elements.count, 1)
        XCTAssertEqual(sut.items.elements.first, element)
    }
}
