import SwiftUI

public struct GradientValueBuilder: RuntimeValueBuilder {
    public let name = "Gradient"
    public let definitions: [RuntimeBuilderDefinition]

    public init() {
        definitions = [
            RuntimeBuilderDefinition(
                parameters: [
                    RuntimeParameter(name: "colors", type: "Color")
                ],
                build: { arguments, _ in
                    let colors = try Self.resolveColors(from: arguments.value(named: "colors"))
                    return .swiftUI(.gradient(Gradient(colors: colors)))
                }
            ),
            RuntimeBuilderDefinition(
                parameters: [
                    RuntimeParameter(name: "stops", type: "Gradient.Stop")
                ],
                build: { arguments, _ in
                    let stops = try Self.resolveStops(from: arguments.value(named: "stops"))
                    return .swiftUI(.gradient(Gradient(stops: stops)))
                }
            )
        ]
    }

    public func populate(type: RuntimeType) {
        let stopType = RuntimeType(builder: GradientStopValueBuilder(), parent: type)
        type.define("Stop", value: .type(stopType))
    }

    private static func resolveColors(from value: RuntimeValue?) throws -> [Color] {
        guard let values = value?.asArray else {
            throw RuntimeError.invalidArgument("Gradient(colors:) expects an array of Color values.")
        }
        return try values.enumerated().map { index, element in
            guard let color = element.asColor else {
                throw RuntimeError.invalidArgument("Gradient(colors:) argument at index \(index) must be a Color.")
            }
            return color
        }
    }

    private static func resolveStops(from value: RuntimeValue?) throws -> [Gradient.Stop] {
        guard let values = value?.asArray else {
            throw RuntimeError.invalidArgument("Gradient(stops:) expects an array of Gradient.Stop values.")
        }
        return try values.enumerated().map { index, element in
            guard let stop = element.asGradientStop else {
                throw RuntimeError.invalidArgument("Gradient(stops:) argument at index \(index) must be a Gradient.Stop.")
            }
            return stop
        }
    }
}
