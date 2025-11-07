import SwiftUI

struct PaddingModifierBuilder: SwiftUIModifierBuilder {
    let name = "padding"

    func apply(arguments: [ResolvedArgument], to base: AnyView) throws -> AnyView {
        switch arguments.count {
        case 0:
            return AnyView(base.padding())
        case 1:
            return try applySingleArgument(arguments[0], to: base)
        case 2:
            let edges = try decodeEdges(from: arguments[0].value)
            let amount = try decodeAmount(from: arguments[1].value)
            return AnyView(base.padding(edges, amount))
        default:
            throw SwiftUIEvaluatorError.invalidArguments("Unsupported padding signature.")
        }
    }

    private func applySingleArgument(_ argument: ResolvedArgument, to base: AnyView) throws -> AnyView {
        switch argument.value {
        case let .number(value):
            return AnyView(base.padding(CGFloat(value)))
        case .memberAccess:
            let edges = try decodeEdges(from: argument.value)
            return AnyView(base.padding(edges))
        default:
            throw SwiftUIEvaluatorError.invalidArguments("Unsupported padding argument.")
        }
    }

    private func decodeEdges(from value: SwiftValue) throws -> Edge.Set {
        guard case let .memberAccess(path) = value, let last = path.last else {
            throw SwiftUIEvaluatorError.invalidArguments("padding edges must be Edge.Set members.")
        }

        switch last {
        case "all": return .all
        case "horizontal": return .horizontal
        case "vertical": return .vertical
        case "top": return .top
        case "bottom": return .bottom
        case "leading": return .leading
        case "trailing": return .trailing
        default:
            throw SwiftUIEvaluatorError.invalidArguments("Unsupported Edge.Set value \(last).")
        }
    }

    private func decodeAmount(from value: SwiftValue) throws -> CGFloat {
        guard case let .number(number) = value else {
            throw SwiftUIEvaluatorError.invalidArguments("Padding amount must be numeric.")
        }
        return CGFloat(number)
    }
}
