import SwiftUI

struct RoundedRectangleViewBuilder: SwiftUIViewBuilder {
    let name = "RoundedRectangle"

    func makeView(arguments: [ResolvedArgument]) throws -> AnyView {
        let radius = try decodeCornerRadius(from: arguments)
        let style = try decodeStyle(from: arguments.first { $0.label == "style" }?.value)
        return AnyView(RoundedRectangle(cornerRadius: radius, style: style))
    }

    private func decodeCornerRadius(from arguments: [ResolvedArgument]) throws -> CGFloat {
        if let labeled = arguments.first(where: { $0.label == "cornerRadius" }) {
            return try number(from: labeled.value)
        }

        if let unlabeled = arguments.first(where: { $0.label == nil && $0.value.resolvedClosure == nil }) {
            return try number(from: unlabeled.value)
        }

        throw SwiftUIEvaluatorError.invalidArguments("RoundedRectangle requires a cornerRadius argument.")
    }

    private func decodeStyle(from value: SwiftValue?) throws -> RoundedCornerStyle {
        guard let value else { return .circular }
        guard case .memberAccess(let path) = value, let last = path.last else {
            throw SwiftUIEvaluatorError.invalidArguments("style expects RoundedCornerStyle members (e.g. .continuous).")
        }

        switch last.lowercased() {
        case "circular":
            return .circular
        case "continuous":
            return .continuous
        default:
            throw SwiftUIEvaluatorError.invalidArguments("Unsupported RoundedRectangle style \(last).")
        }
    }

    private func number(from value: SwiftValue) throws -> CGFloat {
        switch value.resolvingStateReference() {
        case .number(let double):
            return CGFloat(double)
        case .optional(let wrapped):
            guard let unwrapped = wrapped?.unwrappedOptional() else {
                throw SwiftUIEvaluatorError.invalidArguments("cornerRadius cannot be nil.")
            }
            return try number(from: unwrapped)
        default:
            throw SwiftUIEvaluatorError.invalidArguments("cornerRadius expects a numeric literal.")
        }
    }
}
