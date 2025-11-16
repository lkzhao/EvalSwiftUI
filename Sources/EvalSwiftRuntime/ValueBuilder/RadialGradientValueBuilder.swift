import SwiftUI

public struct RadialGradientValueBuilder: RuntimeValueBuilder {
    public let name = "RadialGradient"
    public let definitions: [RuntimeBuilderDefinition]

    public init() {
        definitions = [
            RuntimeBuilderDefinition(
                parameters: [
                    RuntimeParameter(name: "gradient", type: "Gradient"),
                    RuntimeParameter(name: "center", type: "UnitPoint", defaultValue: .swiftUI(.unitPoint(.center))),
                    RuntimeParameter(name: "startRadius", type: "Double"),
                    RuntimeParameter(name: "endRadius", type: "Double")
                ],
                build: { arguments, _ in
                    let gradient = try Self.requireGradient(arguments.value(named: "gradient"))
                    let center = arguments.value(named: "center")?.asUnitPoint ?? .center
                    let startRadius = try Self.requireRadius(arguments.value(named: "startRadius"), label: "startRadius")
                    let endRadius = try Self.requireRadius(arguments.value(named: "endRadius"), label: "endRadius")

                    let style = AnyShapeStyle(
                        RadialGradient(
                            gradient: gradient,
                            center: center,
                            startRadius: startRadius,
                            endRadius: endRadius
                        )
                    )
                    return .swiftUI(.shapeStyle(style))
                }
            )
        ]
    }

    private static func requireGradient(_ value: RuntimeValue?) throws -> Gradient {
        guard let gradient = value?.asGradient else {
            throw RuntimeError.invalidArgument("RadialGradient expects a Gradient value for 'gradient'.")
        }
        return gradient
    }

    private static func requireRadius(_ value: RuntimeValue?, label: String) throws -> CGFloat {
        guard let radius = value?.asCGFloat else {
            throw RuntimeError.invalidArgument("RadialGradient requires a numeric value for '\(label)'.")
        }
        return radius
    }
}
