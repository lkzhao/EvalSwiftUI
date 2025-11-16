import SwiftUI

public struct BlendModeModifierBuilder: RuntimeMethodBuilder {
    public let name = "blendMode"
    public let definitions: [RuntimeMethodDefinition]

    public init() {
        definitions = [
            RuntimeViewMethodDefinition(
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
