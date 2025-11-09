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
            argument.label == nil && (try? argument.value.asString()) != nil
        }) else {
            return nil
        }
        return try argument.value.asString()
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

extension SwiftValue {
    func boolBinding(description: String) throws -> Binding<Bool> {
        guard case .bool = unwrappedOptional()?.payload else {
            throw SwiftUIEvaluatorError.invalidArguments("\(description) must be backed by a boolean @State variable.")
        }
        let writesOptional = isOptional
        return Binding(
            get: { [weak self] in
                guard case let .bool(boolValue) = self?.unwrappedOptional()?.payload else {
                    assertionFailure("Boolean binding resolved to a non-boolean value.")
                    return false
                }
                return boolValue
            },
            set: { [weak self] (newValue: Bool) in
                if writesOptional {
                    self?.payload = .optional(.bool(newValue))
                } else {
                    self?.payload = .bool(newValue)
                }
            }
        )
    }
}
