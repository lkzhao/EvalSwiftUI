import SwiftUI

public struct LinearGradientValueBuilder: RuntimeValueBuilder {
    public let name = "LinearGradient"
    public let definitions: [RuntimeBuilderDefinition]

    public init() {
        definitions = [
            RuntimeBuilderDefinition(
                parameters: [
                    RuntimeParameter(name: "gradient", type: "Gradient"),
                    RuntimeParameter(name: "startPoint", type: "UnitPoint"),
                    RuntimeParameter(name: "endPoint", type: "UnitPoint")
                ],
                build: { arguments, _ in
                    let gradient = try Self.requireGradient(arguments.value(named: "gradient"), context: "LinearGradient(gradient:)")
                    let startPoint = try Self.requireUnitPoint(arguments.value(named: "startPoint"), label: "startPoint")
                    let endPoint = try Self.requireUnitPoint(arguments.value(named: "endPoint"), label: "endPoint")

                    let style = AnyShapeStyle(
                        LinearGradient(gradient: gradient, startPoint: startPoint, endPoint: endPoint)
                    )
                    return .swiftUI(.shapeStyle(style))
                }
            ),
            RuntimeBuilderDefinition(
                parameters: [
                    RuntimeParameter(label: "colors", name: "colors", type: "[Color]"),
                    RuntimeParameter(name: "startPoint", type: "UnitPoint"),
                    RuntimeParameter(name: "endPoint", type: "UnitPoint")
                ],
                build: { arguments, _ in
                    let gradient = try Self.makeGradient(from: arguments.value(named: "colors"))
                    let startPoint = try Self.requireUnitPoint(arguments.value(named: "startPoint"), label: "startPoint")
                    let endPoint = try Self.requireUnitPoint(arguments.value(named: "endPoint"), label: "endPoint")
                    let style = AnyShapeStyle(
                        LinearGradient(gradient: gradient, startPoint: startPoint, endPoint: endPoint)
                    )
                    return .swiftUI(.shapeStyle(style))
                }
            )
        ]
    }

    private static func requireGradient(_ value: RuntimeValue?, context: String) throws -> Gradient {
        guard let gradient = value?.asGradient else {
            throw RuntimeError.invalidArgument("\(context) expects a Gradient value.")
        }
        return gradient
    }

    private static func requireUnitPoint(_ value: RuntimeValue?, label: String) throws -> UnitPoint {
        guard let point = value?.asUnitPoint else {
            throw RuntimeError.invalidArgument("LinearGradient requires a UnitPoint for '\(label)'.")
        }
        return point
    }

    private static func makeGradient(from value: RuntimeValue?) throws -> Gradient {
        guard let array = value?.asArray else {
            throw RuntimeError.invalidArgument("LinearGradient(colors:) expects an array of Color values.")
        }
        let colors: [Color] = try array.map { element in
            guard let color = element.asColor else {
                throw RuntimeError.invalidArgument("LinearGradient(colors:) expects Color values.")
            }
            return color
        }
        return Gradient(colors: colors)
    }
}
