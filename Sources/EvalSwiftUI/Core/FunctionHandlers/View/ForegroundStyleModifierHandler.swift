import SwiftUI

struct ForegroundStyleModifierHandler: MemberFunctionHandler {
    let name = "foregroundStyle"

    func call(
        baseValue: SwiftValue?,
        arguments: [ResolvedArgument],
        context: any SwiftUIEvaluatorContext
    ) throws -> SwiftValue {
        guard let baseView = baseValue?.asAnyView() else {
            throw SwiftUIEvaluatorError.invalidArguments("foregroundStyle modifier requires a view receiver.")
        }
        guard let argument = arguments.first else {
            throw SwiftUIEvaluatorError.invalidArguments("foregroundStyle requires at least one argument.")
        }

        guard case let .memberAccess(path) = argument.value.payload,
              let last = path.last else {
            throw SwiftUIEvaluatorError.invalidArguments("foregroundStyle expects a known style or Color.")
        }

        switch last.lowercased() {
        case "tint":
            return .view(AnyView(baseView.foregroundStyle(.tint)))
        case "primary":
            return .view(AnyView(baseView.foregroundStyle(Color.primary)))
        case "secondary":
            return .view(AnyView(baseView.foregroundStyle(Color.secondary)))
        default:
            break
        }

        if let color = color(from: last) {
            return .view(AnyView(baseView.foregroundStyle(color)))
        }

        throw SwiftUIEvaluatorError.invalidArguments("Unsupported foreground style \(last).")
    }

    private func color(from name: String) -> Color? {
        switch name.lowercased() {
        case "black": return .black
        case "blue": return .blue
        case "brown": return .brown
        case "cyan": return .cyan
        case "gray": return .gray
        case "green": return .green
        case "orange": return .orange
        case "pink": return .pink
        case "purple": return .purple
        case "red": return .red
        case "white": return .white
        case "yellow": return .yellow
        default:
            return nil
        }
    }
}
