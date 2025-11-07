import SwiftSyntax

struct ViewNode {
    let constructor: ViewConstructor
    var modifiers: [ModifierNode]
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
        case closure(ClosureExprSyntax)
    }

    let label: String?
    let value: Value
}

public struct ResolvedArgument {
    public let label: String?
    public let value: SwiftValue
}

public enum SwiftValue {
    case string(String)
    case memberAccess([String])
    case viewContent(ViewContent)
}

