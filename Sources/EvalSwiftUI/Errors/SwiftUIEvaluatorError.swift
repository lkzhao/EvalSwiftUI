import Foundation

enum SwiftUIEvaluatorError: Error, LocalizedError {
    case missingRootExpression
    case unsupportedExpression(String)
    case invalidArguments(String)
    case unsupportedModifier(String)
    case unknownView(String)

    var errorDescription: String? {
        switch self {
        case .missingRootExpression:
            return "Expected a top-level expression."
        case .unsupportedExpression(let message):
            return "Unsupported expression: \(message)"
        case .invalidArguments(let message):
            return "Invalid arguments: \(message)"
        case .unsupportedModifier(let name):
            return "Modifier .\(name)() is not supported."
        case .unknownView(let name):
            return "View \(name) is not registered."
        }
    }
}
