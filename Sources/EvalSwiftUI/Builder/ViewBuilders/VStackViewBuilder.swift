import SwiftUI

struct VStackViewBuilder: SwiftUIViewBuilder {
    let name = "VStack"

    func makeView(arguments: [ResolvedArgument]) throws -> AnyView {
        guard let closure = arguments.first(where: { argument in
            argument.value.resolvedClosure != nil
        })?.value.resolvedClosure else {
            throw SwiftUIEvaluatorError.invalidArguments("VStack requires a content closure.")
        }
        let content = try closure.makeViewContent()

        let alignment = try decodeAlignment(from: arguments.first { $0.label == "alignment" }?.value)
        let spacing = try decodeSpacing(from: arguments.first { $0.label == "spacing" }?.value)
        let views = try content.renderViews()
        return AnyView(VStack(alignment: alignment, spacing: spacing) {
            ForEach(Array(views.enumerated()), id: \.0) { _, view in
                view
            }
        })
    }

    private func decodeAlignment(from value: SwiftValue?) throws -> HorizontalAlignment {
        guard let value else { return .center }

        guard case let .memberAccess(path) = value.payload, let last = path.last else {
            throw SwiftUIEvaluatorError.invalidArguments("alignment expects a HorizontalAlignment member.")
        }

        switch last {
        case "leading": return .leading
        case "trailing": return .trailing
        case "center": return .center
        default:
            throw SwiftUIEvaluatorError.invalidArguments("Unsupported VStack alignment \(last).")
        }
    }

    private func decodeSpacing(from value: SwiftValue?) throws -> CGFloat? {
        guard let value else { return nil }

        switch value.payload {
        case let .number(number):
            return CGFloat(number)
        default:
            throw SwiftUIEvaluatorError.invalidArguments("spacing expects a numeric literal.")
        }
    }
}
