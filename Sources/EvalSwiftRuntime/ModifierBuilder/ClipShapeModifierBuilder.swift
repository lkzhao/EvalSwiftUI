import SwiftUI

public struct ClipShapeModifierBuilder: RuntimeModifierBuilder {
    public let name = "clipShape"
    public let definitions: [RuntimeModifierDefinition]

    public init() {
        definitions = [
            RuntimeViewModifierDefinition(
                parameters: [
                    RuntimeParameter(label: "_", name: "shape", type: "Shape"),
                    RuntimeParameter(
                        name: "style",
                        type: "FillStyle",
                        defaultValue: .swiftUI(.fillStyle(FillStyle()))
                    )
                ],
                apply: { view, arguments, _ in
                    guard let shape = arguments.value(named: "shape")?.asShape else {
                        throw RuntimeError.invalidArgument("clipShape expects a Shape value.")
                    }
                    let style = arguments.value(named: "style")?.asFillStyle ?? FillStyle()
                    return AnyView(view.clipShape(shape, style: style))
                }
            )
        ]
    }
}
