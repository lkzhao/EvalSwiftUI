import Foundation

public enum RuntimeError: Error, CustomStringConvertible {
    case unknownIdentifier(String)
    case unknownFunction(String)
    case unknownView(String)
    case invalidArgumentCount(expected: Int, got: Int, function: String)
    case unsupportedExpression(String)
    case invalidViewResult(String)
    case invalidViewArgument(String)
    case returnOutsideFunction

    public var description: String {
        switch self {
        case .unknownIdentifier(let name):
            return "Unknown identifier: \(name)"
        case .unknownFunction(let name):
            return "Unknown function: \(name)"
        case .unknownView(let name):
            return "Unknown view: \(name)"
        case .invalidArgumentCount(let expected, let got, let function):
            return "Function \(function) expected \(expected) arguments but received \(got)."
        case .unsupportedExpression(let description):
            return "Unsupported expression: \(description)"
        case .invalidViewResult(let description):
            return "Invalid view result: \(description)"
        case .invalidViewArgument(let description):
            return "Invalid view argument: \(description)"
        case .returnOutsideFunction:
            return "Return statement encountered outside of a function context."
        }
    }
}
