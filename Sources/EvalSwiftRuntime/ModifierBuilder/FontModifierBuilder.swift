import SwiftUI

public struct FontModifierBuilder: RuntimeMethodBuilder {
    public let name = "font"
    public let definitions: [RuntimeMethodDefinition]

    public init() {
        definitions = [
            RuntimeViewMethodDefinition(
                parameters: [
                    RuntimeParameter(label: "_", name: "font", type: "Font")
                ],
                apply: { view, arguments, _ in
                    guard let font = arguments.value(named: "font")?.asFont else {
                        throw RuntimeError.invalidArgument(".font expects a Font value.")
                    }
                    return AnyView(view.font(font))
                }
            )
        ]
    }
}
