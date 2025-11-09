import SwiftUI

struct ButtonViewBuilder: SwiftUIViewBuilder {
    let name = "Button"

    func makeView(arguments: [ResolvedArgument]) throws -> AnyView {
        let actionClosure = try findActionClosure(in: arguments)
        let action = actionClosure.makeActionContent()
        let role = try decodeRole(from: arguments.first { $0.label == "role" }?.value)

        if let labelClosure = labelClosure(from: arguments) {
            let labelView = try makeSingleView(from: labelClosure)
            return AnyView(
                Button(role: role) {
                    try? action.perform()
                } label: {
                    labelView
                }
            )
        }

        if let title = try decodeTitle(from: arguments) {
            return AnyView(
                Button(role: role) {
                    try? action.perform()
                } label: {
                    Text(title)
                }
            )
        }

        throw SwiftUIEvaluatorError.invalidArguments("Button requires a title string or a label closure.")
    }

    private func findActionClosure(in arguments: [ResolvedArgument]) throws -> ResolvedClosure {
        guard let closure = arguments.first(where: { argument in
            argument.label == nil && argument.value.resolvedClosure != nil
        })?.value.resolvedClosure else {
            throw SwiftUIEvaluatorError.invalidArguments("Button requires an action closure.")
        }
        return closure
    }

    private func labelClosure(from arguments: [ResolvedArgument]) -> ResolvedClosure? {
        arguments.first(where: { argument in
            argument.label == "label" && argument.value.resolvedClosure != nil
        })?.value.resolvedClosure
    }

    private func makeSingleView(from closure: ResolvedClosure) throws -> AnyView {
        let content = try closure.makeViewContent()
        let views = try content.renderViews()
        guard let view = views.first, views.count == 1 else {
            throw SwiftUIEvaluatorError.invalidArguments("Button label closures must return exactly one view.")
        }
        return view
    }

    private func decodeTitle(from arguments: [ResolvedArgument]) throws -> String? {
        guard let argument = arguments.first(where: { argument in
            argument.label == nil && (try? argument.value.asString()) != nil
        }) else {
            return nil
        }
        return try argument.value.asString()
    }

    private func decodeRole(from value: SwiftValue?) throws -> ButtonRole? {
        guard let value else { return nil }
        guard case let .memberAccess(path) = value.payload, let last = path.last else {
            throw SwiftUIEvaluatorError.invalidArguments("Button roles must be specified using ButtonRole members.")
        }

        switch last.lowercased() {
        case "destructive": return .destructive
        case "cancel": return .cancel
        default:
            throw SwiftUIEvaluatorError.invalidArguments("Unsupported Button role \(last).")
        }
    }
}
