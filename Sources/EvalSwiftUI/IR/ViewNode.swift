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
}

public struct FunctionCallValue {
    public let name: [String]
    public let arguments: [ResolvedArgument]
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
}
