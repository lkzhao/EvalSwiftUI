import SwiftUI

public struct GradientStopValueBuilder: RuntimeValueBuilder {
    public let name = "Gradient.Stop"
    public let definitions: [RuntimeBuilderDefinition]

    public init() {
        definitions = [
            RuntimeBuilderDefinition(
                parameters: [
                    RuntimeParameter(name: "color", type: "Color"),
                    RuntimeParameter(name: "location", type: "Double")
                ],
                build: { arguments, _ in
                    guard let color = arguments.value(named: "color")?.asColor else {
                        throw RuntimeError.invalidArgument("Gradient.Stop(color:) expects a Color value.")
                    }
                    guard let location = arguments.value(named: "location")?.asCGFloat else {
                        throw RuntimeError.invalidArgument("Gradient.Stop(location:) expects a numeric value.")
                    }
                    return .swiftUI(.gradientStop(Gradient.Stop(color: color, location: location)))
                }
            )
        ]
    }
}
