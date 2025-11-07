import SwiftUI

struct ForegroundStyleModifierBuilder: SwiftUIModifierBuilder {
    let name = "foregroundStyle"

    func apply(arguments: [ResolvedArgument], to base: AnyView) throws -> AnyView {
        guard let argument = arguments.first else {
            throw SwiftUIEvaluatorError.invalidArguments("foregroundStyle requires at least one argument.")
        }

        guard case let .memberAccess(path) = argument.value,
              let last = path.last else {
            throw SwiftUIEvaluatorError.invalidArguments("foregroundStyle expects a known style or Color.")
        }

        switch last.lowercased() {
        case "tint":
            return AnyView(base.foregroundStyle(.tint))
        case "primary":
            return AnyView(base.foregroundStyle(Color.primary))
        case "secondary":
            return AnyView(base.foregroundStyle(Color.secondary))
        default:
            break
        }

        if let color = color(from: last) {
            return AnyView(base.foregroundStyle(color))
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
