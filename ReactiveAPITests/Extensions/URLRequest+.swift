import Foundation

extension URLRequest {
    func urlHasPrefix(_ prefix: String) -> Bool {
        return self.url!.absoluteString.hasPrefix(prefix)
    }

    func urlIsEquals(_ url: String) -> Bool {
        return self.url!.absoluteString == url
    }
}
