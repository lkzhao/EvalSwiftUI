import SwiftSyntax

struct ViewNode {
    let constructor: ViewConstructor
    var modifiers: [ModifierNode]
    let scope: ExpressionScope
}

struct ViewConstructor {
    let name: String
    let arguments: [ArgumentNode]
}

struct ModifierNode {
    let name: String
    let arguments: [ArgumentNode]
}

struct ArgumentNode {
    enum Value {
        case expression(ExprSyntax)
        case closure(ClosureExprSyntax, scope: ExpressionScope)
    }

    let label: String?
    let value: Value
}

public struct ResolvedArgument {
    public let label: String?
    public let value: SwiftValue
}

public indirect enum SwiftValue {
    case string(String)
    case memberAccess([String])
    case viewContent(ViewContent)
    case number(Double)
    case functionCall(FunctionCallValue)
    case bool(Bool)
    case optional(SwiftValue?)
    case array([SwiftValue])
    case range(RangeValue)
    case keyPath(KeyPathValue)
    case dictionary([String: SwiftValue])
}

public struct FunctionCallValue {
    public let name: [String]
    public let arguments: [ResolvedArgument]
}

public struct KeyPathValue {
    public let components: [String]
}

public struct RangeValue {
    public enum Style {
        case halfOpen
        case closed
    }

    public let lowerBound: Int
    public let upperBound: Int
    public let style: Style
}

extension RangeValue {
    func elements() -> [Int] {
        switch style {
        case .halfOpen:
            if lowerBound >= upperBound {
                return []
            }
            return Array(lowerBound..<upperBound)
        case .closed:
            return Array(lowerBound...upperBound)
        }
    }

    func contains(_ value: Int) -> Bool {
        switch style {
        case .halfOpen:
            return value >= lowerBound && value < upperBound
        case .closed:
            return value >= lowerBound && value <= upperBound
        }
    }
}

typealias ExpressionScope = [String: SwiftValue]

extension SwiftValue {
    var typeDescription: String {
        switch self {
        case .string:
            return "string"
        case .memberAccess:
            return "member reference"
        case .viewContent:
            return "view content"
        case .number:
            return "number"
        case .functionCall:
            return "function call"
        case .bool:
            return "bool"
        case .optional:
            return "optional"
        case .array:
            return "array"
        case .range:
            return "range"
        case .keyPath:
            return "keyPath"
        case .dictionary:
            return "dictionary"
        }
    }

    func unwrappedOptional() -> SwiftValue? {
        switch self {
        case .optional(let wrapped):
            guard let wrapped else { return nil }
            return wrapped.unwrappedOptional()
        default:
            return self
        }
    }

    var isOptional: Bool {
        if case .optional = self {
            return true
        }
        return false
    }

    func equals(_ other: SwiftValue) -> Bool {
        switch (self, other) {
        case (.string(let left), .string(let right)):
            return left == right
        case (.number(let left), .number(let right)):
            return left == right
        case (.bool(let left), .bool(let right)):
            return left == right
        case (.memberAccess(let left), .memberAccess(let right)):
            return memberPathsEqual(left, right)
        case (.optional(let left), .optional(let right)):
            switch (left?.unwrappedOptional(), right?.unwrappedOptional()) {
            case (nil, nil):
                return true
            case let (lhsValue?, rhsValue?):
                return lhsValue.equals(rhsValue)
            default:
                return false
            }
        case (.optional(let wrapped), _):
            if let unwrapped = wrapped?.unwrappedOptional() {
                return unwrapped.equals(other)
            }
            return false
        case (_, .optional):
            return other.equals(self)
        default:
            return false
        }
    }
}

private func memberPathsEqual(_ lhs: [String], _ rhs: [String]) -> Bool {
    if lhs == rhs {
        return true
    }

    guard let lhsLast = lhs.last, let rhsLast = rhs.last else {
        return false
    }

    return lhsLast == rhsLast
}
