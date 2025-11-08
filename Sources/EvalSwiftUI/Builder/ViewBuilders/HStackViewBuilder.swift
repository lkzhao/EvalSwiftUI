import SwiftUI

struct HStackViewBuilder: SwiftUIViewBuilder {
    let name = "HStack"

    func makeView(arguments: [ResolvedArgument]) throws -> AnyView {
        guard let closure = arguments.first(where: { argument in
            argument.value.resolvedClosure != nil
        })?.value.resolvedClosure else {
            throw SwiftUIEvaluatorError.invalidArguments("HStack requires a content closure.")
        }
        let content = try closure.makeViewContent()

        let alignment = try decodeAlignment(from: arguments.first { $0.label == "alignment" }?.value)
        let spacing = try decodeSpacing(from: arguments.first { $0.label == "spacing" }?.value)
        let views = try content.renderViews()
        return AnyView(HStack(alignment: alignment, spacing: spacing) {
            ForEach(Array(views.enumerated()), id: \.0) { _, view in
                view
            }
        })
    }

    private func decodeAlignment(from value: SwiftValue?) throws -> VerticalAlignment {
        guard let value else { return .center }

        guard case let .memberAccess(path) = value, let last = path.last else {
            throw SwiftUIEvaluatorError.invalidArguments("alignment expects a VerticalAlignment member.")
        }

        switch last {
        case "top": return .top
        case "bottom": return .bottom
        case "center": return .center
        default:
            throw SwiftUIEvaluatorError.invalidArguments("Unsupported HStack alignment \(last).")
        }
    }

    private func decodeSpacing(from value: SwiftValue?) throws -> CGFloat? {
        guard let value else { return nil }

        switch value {
        case let .number(number):
            return CGFloat(number)
        default:
            throw SwiftUIEvaluatorError.invalidArguments("spacing expects a numeric literal.")
        }
    }
}
