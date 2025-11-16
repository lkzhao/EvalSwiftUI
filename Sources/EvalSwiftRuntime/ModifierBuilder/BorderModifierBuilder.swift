import SwiftUI

public struct BorderModifierBuilder: RuntimeMethodBuilder {
    public let name = "border"
    public let definitions: [RuntimeMethodDefinition]

    public init() {
        definitions = [
            RuntimeViewMethodDefinition(
                parameters: [
                    RuntimeParameter(label: "_", name: "style", type: "ShapeStyle"),
                    RuntimeParameter(name: "width", type: "Double", defaultValue: .double(1))
                ],
                apply: { view, arguments, _ in
                    guard let style = arguments.value(named: "style")?.asShapeStyle else {
                        throw RuntimeError.invalidArgument("border expects a ShapeStyle or Color value.")
                    }
                    let width = arguments.value(named: "width")?.asCGFloat ?? 1
                    return AnyView(view.border(style, width: width))
                }
            )
        ]
    }
}
