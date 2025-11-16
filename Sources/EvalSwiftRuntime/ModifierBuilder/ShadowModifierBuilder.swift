import SwiftUI

public struct ShadowModifierBuilder: RuntimeMethodBuilder {
    public let name = "shadow"
    public let definitions: [RuntimeMethodDefinition]
    private static let defaultShadowColor = Color(.sRGBLinear, white: 0, opacity: 0.33)

    public init() {
        definitions = [
            RuntimeViewMethodDefinition(
                parameters: [
                    RuntimeParameter(
                        name: "color",
                        type: "Color",
                        defaultValue: .swiftUI(.color(Self.defaultShadowColor))
                    ),
                    RuntimeParameter(name: "radius", type: "Double"),
                    RuntimeParameter(name: "x", type: "Double", defaultValue: .double(0)),
                    RuntimeParameter(name: "y", type: "Double", defaultValue: .double(0))
                ],
                apply: { view, arguments, _ in
                    guard let radius = arguments.value(named: "radius")?.asCGFloat else {
                        throw RuntimeError.invalidArgument("shadow(radius:) expects a numeric radius.")
                    }
                    let x = arguments.value(named: "x")?.asCGFloat ?? 0
                    let y = arguments.value(named: "y")?.asCGFloat ?? 0
                    let color = arguments.value(named: "color")?.asColor ?? Self.defaultShadowColor
                    return AnyView(
                        view.shadow(color: color, radius: radius, x: x, y: y)
                    )
                }
            ),
            RuntimeViewMethodDefinition(
                parameters: [
                    RuntimeParameter(name: "radius", type: "Double"),
                    RuntimeParameter(name: "x", type: "Double", defaultValue: .double(0)),
                    RuntimeParameter(name: "y", type: "Double", defaultValue: .double(0))
                ],
                apply: { view, arguments, _ in
                    guard let radius = arguments.value(named: "radius")?.asCGFloat else {
                        throw RuntimeError.invalidArgument("shadow(radius:) expects a numeric radius.")
                    }
                    let x = arguments.value(named: "x")?.asCGFloat ?? 0
                    let y = arguments.value(named: "y")?.asCGFloat ?? 0
                    return AnyView(
                        view.shadow(radius: radius, x: x, y: y)
                    )
                }
            )
        ]
    }
}
