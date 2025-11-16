import SwiftUI

public struct ImageScaleModifierBuilder: RuntimeMethodBuilder {
    public let name = "imageScale"
    public let definitions: [RuntimeMethodDefinition]

    public init() {
        definitions = [
            RuntimeViewMethodDefinition(
                parameters: [
                    RuntimeParameter(label: "_", name: "scale", type: "Image.Scale")
                ],
                apply: { view, arguments, _ in
                    guard let scale = arguments.value(named: "scale")?.asImageScale else {
                        throw RuntimeError.invalidArgument("imageScale expects an Image.Scale value.")
                    }
                    return AnyView(view.imageScale(scale))
                }
            )
        ]
    }
}
