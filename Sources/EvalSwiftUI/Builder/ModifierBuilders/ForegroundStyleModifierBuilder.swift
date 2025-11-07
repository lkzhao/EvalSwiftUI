import SwiftUI

struct ForegroundStyleModifierBuilder: SwiftUIModifierBuilder {
    let name = "foregroundStyle"

    func apply(arguments: [ResolvedArgument], to base: AnyView) throws -> AnyView {
        guard let argument = arguments.first else {
            throw SwiftUIEvaluatorError.invalidArguments("foregroundStyle requires at least one argument.")
        }

        guard case let .memberAccess(path) = argument.value,
              let last = path.last else {
            throw SwiftUIEvaluatorError.invalidArguments("foregroundStyle expects a style like .tint.")
        }

        switch last {
        case "tint":
            return AnyView(base.foregroundStyle(.tint))
        default:
            throw SwiftUIEvaluatorError.invalidArguments("Unsupported foreground style \(last).")
        }
    }
}
