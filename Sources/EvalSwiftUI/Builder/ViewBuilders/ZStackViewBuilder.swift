import SwiftUI

struct ZStackViewBuilder: SwiftUIViewBuilder {
    let name = "ZStack"

    func makeView(arguments: [ResolvedArgument]) throws -> AnyView {
        guard let contentArg = arguments.first(where: { argument in
            if case .viewContent = argument.value { return true }
            return false
        }), case let .viewContent(content) = contentArg.value else {
            throw SwiftUIEvaluatorError.invalidArguments("ZStack requires a content closure.")
        }

        let alignment = try decodeAlignment(from: arguments.first { $0.label == "alignment" }?.value)
        let views = try content.renderViews()
        return AnyView(ZStack(alignment: alignment) {
            ForEach(Array(views.enumerated()), id: \.0) { _, view in
                view
            }
        })
    }

    private func decodeAlignment(from value: SwiftValue?) throws -> Alignment {
        guard let value else { return .center }

        guard case let .memberAccess(path) = value, let last = path.last else {
            throw SwiftUIEvaluatorError.invalidArguments("alignment expects an Alignment member.")
        }

        switch last {
        case "center": return .center
        case "leading": return .leading
        case "trailing": return .trailing
        case "top": return .top
        case "bottom": return .bottom
        case "topLeading": return .topLeading
        case "topTrailing": return .topTrailing
        case "bottomLeading": return .bottomLeading
        case "bottomTrailing": return .bottomTrailing
        default:
            throw SwiftUIEvaluatorError.invalidArguments("Unsupported ZStack alignment \(last).")
        }
    }
}
