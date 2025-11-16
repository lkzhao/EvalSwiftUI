import SwiftUI

public struct AngularGradientValueBuilder: RuntimeValueBuilder {
    public let name = "AngularGradient"
    public let definitions: [RuntimeBuilderDefinition]

    public init() {
        definitions = [
            RuntimeBuilderDefinition(
                parameters: [
                    RuntimeParameter(name: "gradient", type: "Gradient"),
                    RuntimeParameter(name: "center", type: "UnitPoint", defaultValue: .swiftUI(.unitPoint(.center))),
                    RuntimeParameter(name: "startAngle", type: "Angle"),
                    RuntimeParameter(name: "endAngle", type: "Angle")
                ],
                build: { arguments, _ in
                    let gradient = try Self.requireGradient(arguments.value(named: "gradient"))
                    let center = arguments.value(named: "center")?.asUnitPoint ?? .center
                    let startAngle = try Self.requireAngle(arguments.value(named: "startAngle"), label: "startAngle")
                    let endAngle = try Self.requireAngle(arguments.value(named: "endAngle"), label: "endAngle")

                    let style = AnyShapeStyle(
                        AngularGradient(
                            gradient: gradient,
                            center: center,
                            startAngle: startAngle,
                            endAngle: endAngle
                        )
                    )
                    return .swiftUI(.shapeStyle(style))
                }
            )
        ]
    }

    private static func requireGradient(_ value: RuntimeValue?) throws -> Gradient {
        guard let gradient = value?.asGradient else {
            throw RuntimeError.invalidArgument("AngularGradient expects a Gradient value for 'gradient'.")
        }
        return gradient
    }

    private static func requireAngle(_ value: RuntimeValue?, label: String) throws -> Angle {
        guard let angle = value?.asAngle else {
            throw RuntimeError.invalidArgument("AngularGradient requires an Angle for '\(label)'.")
        }
        return angle
    }
}
