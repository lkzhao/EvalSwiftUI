import SwiftUI

public struct BlendModeModifierBuilder: RuntimeModifierBuilder {
    public let name = "blendMode"
    public let definitions: [RuntimeModifierDefinition]

    public init() {
        definitions = [
            RuntimeViewModifierDefinition(
                parameters: [
                    RuntimeParameter(label: "_", name: "mode", type: "BlendMode")
                ],
                apply: { view, arguments, _ in
                    guard let mode = arguments.value(named: "mode")?.asBlendMode else {
                        throw RuntimeError.invalidArgument("blendMode expects a BlendMode value.")
                    }
                    return AnyView(view.blendMode(mode))
                }
            )
        ]
    }
}
