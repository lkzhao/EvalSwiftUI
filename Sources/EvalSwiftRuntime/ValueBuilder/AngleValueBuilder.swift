import SwiftUI

public struct AngleValueBuilder: RuntimeValueBuilder {
    public let name = "Angle"
    public let definitions: [RuntimeBuilderDefinition]

    public init() {
        definitions = [
            RuntimeBuilderDefinition(
                parameters: [
                    RuntimeParameter(name: "degrees", type: "Double")
                ],
                build: { arguments, _ in
                    guard let degrees = arguments.value(named: "degrees")?.asDouble else {
                        throw RuntimeError.invalidArgument("Angle(degrees:) expects a numeric value.")
                    }
                    return .swiftUI(.angle(.degrees(degrees)))
                }
            ),
            RuntimeBuilderDefinition(
                parameters: [
                    RuntimeParameter(name: "radians", type: "Double")
                ],
                build: { arguments, _ in
                    guard let radians = arguments.value(named: "radians")?.asDouble else {
                        throw RuntimeError.invalidArgument("Angle(radians:) expects a numeric value.")
                    }
                    return .swiftUI(.angle(.radians(radians)))
                }
            )
        ]
    }
}
