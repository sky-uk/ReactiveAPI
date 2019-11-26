import Foundation

public struct FailableCodable<Base: Codable>: Codable {
    let base: Base?

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        base = try? container.decode(Base.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(base)
    }
}

public struct FailableCodableArray<Element: Codable>: Codable {
    public let elements: [Element]

    public init(elements: [Element]) {
        self.elements = elements
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var elements = [Element]()

        while !container.isAtEnd {
            guard let element = try container.decode(FailableCodable<Element>.self).base else { continue }
            elements.append(element)
        }

        self.init(elements: elements)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(elements)
    }
}
