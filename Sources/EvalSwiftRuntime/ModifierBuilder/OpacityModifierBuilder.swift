import SwiftUI

public struct OpacityModifierBuilder: RuntimeModifierBuilder {
    public let name = "opacity"
    public let definitions: [RuntimeModifierDefinition]

    public init() {
        definitions = [
            RuntimeValueModifierDefinition(
                parameters: [
                    RuntimeParameter(label: "_", name: "value", type: "Double")
                ],
                apply: { base, arguments, _ in
                    guard let value = arguments.value(named: "value")?.asDouble else {
                        throw RuntimeError.invalidArgument("opacity expects a numeric value.")
                    }
                    if let color = base.asColor {
                        return .swiftUI(.color(color.opacity(value)))
                    }
                    if let view = base.asSwiftUIView {
                        return .swiftUI(.view(AnyView(view.opacity(value))))
                    }
                    throw RuntimeError.invalidArgument("opacity modifier requires a SwiftUI view or Color.")
                }
            )
        ]
    }
}
