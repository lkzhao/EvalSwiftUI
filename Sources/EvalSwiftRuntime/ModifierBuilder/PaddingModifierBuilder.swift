import SwiftUI

public struct PaddingModifierBuilder: RuntimeModifierBuilder {
    public let name = "padding"
    public let definitions: [RuntimeModifierDefinition]

    public init() {
        definitions = [
            RuntimeViewModifierDefinition(
                parameters: [],
                apply: { view, _, _ in
                    AnyView(view.padding())
                }
            ),
            RuntimeViewModifierDefinition(
                parameters: [
                    RuntimeParameter(label: "_", name: "value", type: "Double")
                ],
                apply: { view, arguments, _ in
                    guard let amount = arguments.value(named: "value")?.asDouble else {
                        throw RuntimeError.invalidArgument("padding(_:) expects a numeric argument.")
                    }
                    return AnyView(view.padding(CGFloat(amount)))
                }
            )
        ]
    }
}
