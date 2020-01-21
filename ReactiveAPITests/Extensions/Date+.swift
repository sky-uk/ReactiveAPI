import Foundation

extension Date {
    var dateMillis: String {
        let df = DateFormatter()
        df.dateFormat = "y-MM-dd H:m:ss.SSSS"
        return df.string(from: self)
    }
}

