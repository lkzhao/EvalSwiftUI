import SwiftUI

public struct OpacityModifierBuilder: RuntimeModifierBuilder {
    public let name = "opacity"
    public let definitions: [RuntimeModifierDefinition]

    public init() {
        definitions = [
            RuntimeModifierDefinition(
                parameters: [
                    RuntimeParameter(label: "_", name: "value", type: "Double")
                ],
                apply: { view, arguments, _ in
                    guard let value = arguments.value(named: "value")?.asDouble else {
                        throw RuntimeError.invalidArgument("opacity expects a numeric value.")
                    }
                    return AnyView(view.opacity(value))
                }
            )
        ]
    }
}
