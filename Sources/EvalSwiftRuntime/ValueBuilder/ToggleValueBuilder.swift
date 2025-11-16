import SwiftUI

public struct ToggleValueBuilder: RuntimeValueBuilder {
    public let name = "Toggle"
    public let definitions: [RuntimeBuilderDefinition]

    public init() {
        definitions = [
            RuntimeBuilderDefinition(
                parameters: [
                    RuntimeParameter(label: "_", name: "title", type: "String"),
                    RuntimeParameter(name: "isOn", type: "Binding<Bool>")
                ],
                build: { arguments, _ in
                    guard let title = arguments.value(named: "title")?.asString else {
                        throw RuntimeError.invalidArgument("Toggle title must be a String.")
                    }
                    let binding = try Self.makeBoolBinding(from: arguments.value(named: "isOn"))
                    return .swiftUI(.view(AnyView(Toggle(title, isOn: binding))))
                }
            ),
            RuntimeBuilderDefinition(
                parameters: [
                    RuntimeParameter(name: "isOn", type: "Binding<Bool>"),
                    RuntimeParameter(name: "label", type: "() -> Content")
                ],
                build: { arguments, _ in
                    let binding = try Self.makeBoolBinding(from: arguments.value(named: "isOn"))
                    guard let function = arguments.value(named: "label")?.asFunction else {
                        throw RuntimeError.invalidArgument("Toggle label requires a closure.")
                    }
                    let labelView = try Self.makeLabelView(from: function)
                    let toggle = Toggle(isOn: binding) {
                        labelView
                    }
                    return .swiftUI(.view(AnyView(toggle)))
                }
            )
        ]
    }

    private static func makeBoolBinding(from value: RuntimeValue?) throws -> Binding<Bool> {
        guard let runtimeBinding = value?.asBinding else {
            throw RuntimeError.invalidArgument("Toggle requires a Binding<Bool> for isOn.")
        }
        return Binding(
            get: {
                do {
                    return try runtimeBinding.get().asBool ?? false
                } catch {
                    assertionFailure("Failed to read binding: \(error)")
                    return false
                }
            },
            set: { newValue in
                do {
                    try runtimeBinding.set(.bool(newValue))
                } catch {
                    assertionFailure("Failed to set binding: \(error)")
                }
            }
        )
    }

    private static func makeLabelView(from function: RuntimeFunction) throws -> AnyView {
        let renderedValues = try function.renderRuntimeViews()
        if let view = renderedValues.compactMap({ $0.asSwiftUIView }).first {
            return view
        }
        throw RuntimeError.invalidArgument("Toggle label closure must return a SwiftUI view.")
    }
}
