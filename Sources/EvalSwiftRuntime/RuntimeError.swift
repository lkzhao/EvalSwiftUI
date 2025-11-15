import Foundation

public enum RuntimeError: Error, CustomStringConvertible {
    case unknownIdentifier(String)
    case ambiguousIdentifier(String)
    case unknownFunction(String)
    case unknownModifier(String)
    case unknownView(String)
    case invalidArgumentCount(expected: Int, got: Int)
    case unsupportedExpression(String)
    case invalidViewResult(String)
    case invalidArgument(String)
    case returnOutsideFunction
    case unsupportedAssignment(String)

    public var description: String {
        switch self {
        case .ambiguousIdentifier(let name):
            return "Ambiguous identifier: \(name)"
        case .unknownIdentifier(let name):
            return "Unknown identifier: \(name)"
        case .unknownFunction(let name):
            return "Unknown function: \(name)"
        case .unknownModifier(let name):
            return "Unknown view modifier: \(name)"
        case .unknownView(let name):
            return "Unknown view: \(name)"
        case .invalidArgumentCount(let expected, let got):
            return "Function expected \(expected) arguments but received \(got)."
        case .unsupportedExpression(let description):
            return "Unsupported expression: \(description)"
        case .invalidViewResult(let description):
            return "Invalid view result: \(description)"
        case .invalidArgument(let description):
            return "Invalid argument: \(description)"
        case .returnOutsideFunction:
            return "Return statement encountered outside of a function context."
        case .unsupportedAssignment(let description):
            return "Unsupported assignment: \(description)"
        }
    }
}
