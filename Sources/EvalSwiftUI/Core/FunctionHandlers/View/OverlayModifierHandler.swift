import SwiftUI

struct OverlayModifierHandler: MemberFunctionHandler {
    let name = "overlay"

    func call(
        baseValue: SwiftValue?,
        arguments: [ResolvedArgument],
        context: any SwiftUIEvaluatorContext
    ) throws -> SwiftValue {
        guard let baseView = baseValue?.asAnyView() else {
            throw SwiftUIEvaluatorError.invalidArguments("overlay modifier requires a view receiver.")
        }
        let alignment = try decodeAlignment(from: arguments.first { $0.label == "alignment" }?.value)
        let content = try viewContent(from: arguments)
        let renderedViews = try content.renderViews()
        let overlayView = try makeCompositeView(from: renderedViews)

        let transformed = AnyView(
            baseView.overlay(alignment: alignment) {
                overlayView
            }
        )
        return .view(transformed)
    }

    private func viewContent(from arguments: [ResolvedArgument]) throws -> ViewContent {
        guard let closure = arguments.first(where: { argument in
            argument.value.resolvedClosure != nil
        })?.value.resolvedClosure else {
            throw SwiftUIEvaluatorError.invalidArguments("overlay requires a trailing content closure.")
        }
        return try closure.makeViewContent()
    }

    private func makeCompositeView(from views: [AnyView]) throws -> AnyView {
        guard !views.isEmpty else {
            throw SwiftUIEvaluatorError.invalidArguments("overlay closures must return at least one view.")
        }

        if views.count == 1, let first = views.first {
            return first
        }

        let indices = Array(views.indices)
        return AnyView(
            ZStack {
                ForEach(indices, id: \.self) { index in
                    views[index]
                }
            }
        )
    }

    private func decodeAlignment(from value: SwiftValue?) throws -> Alignment {
        guard let value else { return .center }
        guard case let .memberAccess(path) = value.payload, let last = path.last else {
            throw SwiftUIEvaluatorError.invalidArguments("Alignment must be specified using Alignment members.")
        }

        switch last.lowercased() {
        case "center": return .center
        case "leading": return .leading
        case "trailing": return .trailing
        case "top": return .top
        case "bottom": return .bottom
        case "topleading": return .topLeading
        case "toptrailing": return .topTrailing
        case "bottomleading": return .bottomLeading
        case "bottomtrailing": return .bottomTrailing
        default:
            throw SwiftUIEvaluatorError.invalidArguments("Unsupported alignment \(last).")
        }
    }
}
