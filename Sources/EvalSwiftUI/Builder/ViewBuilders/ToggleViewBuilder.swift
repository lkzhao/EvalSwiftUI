import SwiftUI

struct ToggleViewBuilder: SwiftUIViewBuilder {
    let name = "Toggle"

    func makeView(arguments: [ResolvedArgument]) throws -> AnyView {
        guard let bindingArgument = arguments.first(where: { $0.label == "isOn" }) else {
            throw SwiftUIEvaluatorError.invalidArguments("Toggle requires an isOn: binding argument.")
        }
        let binding = try bindingArgument.value.boolBinding(description: "Toggle isOn argument")

        if let closure = labelClosure(from: arguments) {
            let labelView = try makeSingleView(from: closure)
            return AnyView(
                Toggle(isOn: binding) {
                    labelView
                }
            )
        }

        if let title = try decodeTitle(from: arguments) {
            return AnyView(
                Toggle(isOn: binding) {
                    Text(title)
                }
            )
        }

        throw SwiftUIEvaluatorError.invalidArguments("Toggle requires either a title string or a label closure.")
    }

    private func labelClosure(from arguments: [ResolvedArgument]) -> ResolvedClosure? {
        arguments.first(where: { argument in
            argument.label != "isOn" && argument.value.resolvedClosure != nil
        })?.value.resolvedClosure
    }

    private func decodeTitle(from arguments: [ResolvedArgument]) throws -> String? {
        guard let argument = arguments.first(where: { argument in
            argument.label == nil && argument.value.isStringLiteral
        }) else {
            return nil
        }
        guard case let .string(value) = argument.value.resolvingStateReference() else {
            throw SwiftUIEvaluatorError.invalidArguments("Toggle titles must be string literals.")
        }
        return value
    }

    private func makeSingleView(from closure: ResolvedClosure) throws -> AnyView {
        let content = try closure.makeViewContent()
        let views = try content.renderViews()
        guard let view = views.first, views.count == 1 else {
            throw SwiftUIEvaluatorError.invalidArguments("Toggle label closures must return exactly one view.")
        }
        return view
    }
}

private extension SwiftValue {
    var isStringLiteral: Bool {
        if case .string = resolvingStateReference() {
            return true
        }
        return false
    }
}
