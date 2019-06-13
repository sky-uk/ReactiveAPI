import Foundation

struct Resources {
    static let url = URL(string: "https://url.com")!
    static let baseUrl = URL(string: "https://baseurl.com/")!
    static let urlRequest = URLRequest(url: Resources.url)
    static let data = Data(count: 100)
    static let params: [String : Any?] = ["key": "value",
                                          "number": 3,
                                          "nil": nil]
    
    static func httpUrlResponse(code: Int = 200) -> HTTPURLResponse? {
        return HTTPURLResponse(url: Resources.url,
                               statusCode: code,
                               httpVersion: nil,
                               headerFields: nil)
    }
}
