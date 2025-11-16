import SwiftUI

public struct FontModifierBuilder: RuntimeModifierBuilder {
    public let name = "font"
    public let definitions: [RuntimeModifierDefinition]

    public init() {
        definitions = [
            RuntimeViewModifierDefinition(
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
