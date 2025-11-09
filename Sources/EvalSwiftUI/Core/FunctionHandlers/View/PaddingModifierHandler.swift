import SwiftUI

struct PaddingModifierHandler: MemberFunctionHandler {
    let name = "padding"

    func call(
        baseValue: SwiftValue?,
        arguments: [ResolvedArgument],
        context: any SwiftUIEvaluatorContext
    ) throws -> SwiftValue {
        guard let baseView = baseValue?.asAnyView() else {
            throw SwiftUIEvaluatorError.invalidArguments("padding modifier requires a view receiver.")
        }
        let transformed: AnyView
        switch arguments.count {
        case 0:
            transformed = AnyView(baseView.padding())
        case 1:
            transformed = try applySingleArgument(arguments[0], to: baseView)
        case 2:
            let edges = try decodeEdges(from: arguments[0].value)
            let amount = try decodeAmount(from: arguments[1].value)
            transformed = AnyView(baseView.padding(edges, amount))
        default:
            throw SwiftUIEvaluatorError.invalidArguments("Unsupported padding signature.")
        }
        return .view(transformed)
    }

    private func applySingleArgument(_ argument: ResolvedArgument, to base: AnyView) throws -> AnyView {
        switch argument.value.payload {
        case .number, .optional:
            return AnyView(base.padding(try argument.value.asCGFloat()))
        case .memberAccess:
            let edges = try decodeEdges(from: argument.value)
            return AnyView(base.padding(edges))
        default:
            throw SwiftUIEvaluatorError.invalidArguments("Unsupported padding argument.")
        }
    }

    private func decodeEdges(from value: SwiftValue) throws -> Edge.Set {
        guard case let .memberAccess(path) = value.payload, let last = path.last else {
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
        do {
            return try value.asCGFloat()
        } catch {
            throw SwiftUIEvaluatorError.invalidArguments("Padding amount must be numeric.")
        }
    }
}
