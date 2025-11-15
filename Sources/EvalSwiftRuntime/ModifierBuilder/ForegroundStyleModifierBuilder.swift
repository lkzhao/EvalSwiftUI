import SwiftUI

public struct ForegroundStyleModifierBuilder: RuntimeModifierBuilder {
    public let name = "foregroundStyle"
    public let definitions: [RuntimeModifierDefinition]

    public init() {
        definitions = [
            RuntimeViewModifierDefinition(
                parameters: [
                    RuntimeParameter(label: "_", name: "style", type: "ShapeStyle")
                ],
                apply: { view, arguments, _ in
                    guard let style = arguments.value(named: "style")?.asShapeStyle else {
                        throw RuntimeError.invalidArgument("foregroundStyle expects a ShapeStyle value.")
                    }
                    return AnyView(view.foregroundStyle(style))
                }
            )
        ]
    }
}
