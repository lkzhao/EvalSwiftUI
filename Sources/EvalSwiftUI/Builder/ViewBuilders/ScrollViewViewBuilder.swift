import SwiftUI

struct ScrollViewViewBuilder: SwiftUIViewBuilder {
    let name = "ScrollView"

    func makeView(arguments: [ResolvedArgument]) throws -> AnyView {
        let axis = try decodeAxis(from: axisArgument(in: arguments))
        let showsIndicators = try decodeShowsIndicators(from: arguments.first { $0.label == "showsIndicators" }?.value)

        guard let closure = arguments.first(where: { $0.value.resolvedClosure != nil })?.value.resolvedClosure else {
            throw SwiftUIEvaluatorError.invalidArguments("ScrollView requires a content closure.")
        }

        let content = try closure.makeViewContent()
        let views = try content.renderViews()
        let stackedViews = makeContentContainer(for: axis, views: views)

        return AnyView(
            ScrollView(axis, showsIndicators: showsIndicators) {
                stackedViews
            }
        )
    }

    private func axisArgument(in arguments: [ResolvedArgument]) -> SwiftValue? {
        arguments.first { argument in
            argument.label == nil && argument.value.resolvedClosure == nil
        }?.value
    }

    private func decodeAxis(from value: SwiftValue?) throws -> Axis.Set {
        guard let value else { return .vertical }
        guard case .memberAccess(let path) = value.payload, let last = path.last else {
            throw SwiftUIEvaluatorError.invalidArguments("ScrollView axis argument expects Axis.Set members (e.g. .horizontal).")
        }

        switch last.lowercased() {
        case "horizontal":
            return .horizontal
        case "vertical":
            return .vertical
        case "all":
            return [.horizontal, .vertical]
        default:
            throw SwiftUIEvaluatorError.invalidArguments("Unsupported ScrollView axis member \(last).")
        }
    }

    private func decodeShowsIndicators(from value: SwiftValue?) throws -> Bool {
        guard let value else { return true }
        return try value.asBool()
    }

    private func makeContentContainer(for axis: Axis.Set, views: [AnyView]) -> AnyView {
        guard !views.isEmpty else {
            return AnyView(EmptyView())
        }

        if axis == .horizontal {
            return AnyView(
                HStack(spacing: 0) {
                    ForEach(Array(views.enumerated()), id: \.0) { _, view in
                        view
                    }
                }
            )
        }

        return AnyView(
            VStack(spacing: 0) {
                ForEach(Array(views.enumerated()), id: \.0) { _, view in
                    view
                }
            }
        )
    }

}
