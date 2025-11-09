import Foundation

public enum RuntimeValue {
    case number(Double)
    case string(String)
    case bool(Bool)
    case view(ViewDescription)
    case void
}

public struct ViewDescription: Hashable {
    public let name: String
    public let content: String

    public init(name: String, content: String) {
        self.name = name
        self.content = content
    }
}

extension RuntimeValue {
    var asBool: Bool? {
        switch self {
        case .bool(let value):
            return value
        case .number(let number):
            return number != 0
        case .string(let string):
            return !string.isEmpty
        default:
            return nil
        }
    }
}
