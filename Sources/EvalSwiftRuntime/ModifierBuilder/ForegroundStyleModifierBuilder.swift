import SwiftUI

public struct ForegroundStyleModifierBuilder: RuntimeModifierBuilder {
    public let name = "foregroundStyle"
    public let definitions: [RuntimeModifierDefinition]

    public init() {
        definitions = [
            RuntimeModifierDefinition(
                parameters: [
                    RuntimeParameter(label: "_", name: "style", type: "Color")
                ],
                apply: { view, arguments, _ in
                    guard let color = arguments.value(named: "style")?.asColor else {
                        throw RuntimeError.invalidArgument("foregroundStyle expects a Color value.")
                    }
                    return AnyView(view.foregroundStyle(color))
                }
            )
        ]
    }
}
