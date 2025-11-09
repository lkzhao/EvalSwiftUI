import SwiftUI

struct ShadowModifierHandler: MemberFunctionHandler {
    let name = "shadow"

    func call(
        baseValue: SwiftValue?,
        arguments: [ResolvedArgument],
        context: any SwiftUIEvaluatorContext
    ) throws -> SwiftValue {
        guard let baseView = baseValue?.asAnyView() else {
            throw SwiftUIEvaluatorError.invalidArguments("shadow modifier requires a view receiver.")
        }
        let color = try decodeColor(from: arguments.first { $0.label == "color" }?.value)
        let radius = try decodeRadius(from: arguments, colorProvided: color != nil)
        let x = try decodeOffset(named: "x", in: arguments)
        let y = try decodeOffset(named: "y", in: arguments)
        return .view(AnyView(baseView.shadow(color: color ?? defaultShadowColor, radius: radius, x: x, y: y)))
    }

    private func decodeRadius(from arguments: [ResolvedArgument], colorProvided: Bool) throws -> CGFloat {
        if let labeled = arguments.first(where: { $0.label == "radius" }) {
            return try labeled.value.asCGFloat(description: "shadow radius")
        }

        if let unlabeled = arguments.first(where: { $0.label == nil && $0.value.resolvedClosure == nil }) {
            return try unlabeled.value.asCGFloat(description: "shadow radius")
        }

        if colorProvided {
            return 3
        }

        throw SwiftUIEvaluatorError.invalidArguments("shadow requires a radius argument.")
    }

    private func decodeOffset(named name: String, in arguments: [ResolvedArgument]) throws -> CGFloat {
        guard let argument = arguments.first(where: { $0.label == name }) else {
            return 0
        }
        return try argument.value.asCGFloat(description: "shadow \(name)")
    }

    private func decodeColor(from value: SwiftValue?) throws -> Color? {
        guard let value else { return nil }
        guard case .memberAccess(let path) = value.payload, let last = path.last else {
            throw SwiftUIEvaluatorError.invalidArguments("shadow color expects Color members.")
        }
        guard let color = color(from: last) else {
            throw SwiftUIEvaluatorError.invalidArguments("Unsupported shadow color \(last).")
        }
        return color
    }

    private func color(from name: String) -> Color? {
        switch name.lowercased() {
        case "black": return .black
        case "blue": return .blue
        case "brown": return .brown
        case "cyan": return .cyan
        case "gray": return .gray
        case "green": return .green
        case "indigo": return .indigo
        case "mint": return .mint
        case "orange": return .orange
        case "pink": return .pink
        case "purple": return .purple
        case "red": return .red
        case "teal": return .teal
        case "white": return .white
        case "yellow": return .yellow
        default:
            return nil
        }
    }

    private var defaultShadowColor: Color {
        Color.black.opacity(0.33)
    }
}
