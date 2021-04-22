import Foundation

public enum SkyEvent<Element> {

    /// Next element is produced.
    case next(Element)

    /// Sequence terminated with an error.
    case error(Error)

    /// Sequence completed successfully.
    case completed
}

extension SkyEvent {

    /// Is `completed` or `error` event.
    public var isStopEvent: Bool {
        switch self {
            case .completed, .error(_):
                return true
            default:
                return false
        }
    }

    /// If `next` event, returns element value.
    public var element: Element? {
        switch self {
            case .next(let element):
                return element
            default:
                return nil
        }
    }

    /// If `error` event, returns error.
    public var error: Error? {
        switch self {
            case .error(let error):
                return error
            default:
                return nil
        }
    }

    /// If `completed` event, returns `true`.
    public var isCompleted: Bool {
        switch self {
            case .completed:
                return true
            default:
                return false
        }
    }
}

