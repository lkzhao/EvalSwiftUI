import SwiftUI

public struct FillStyleValueBuilder: RuntimeValueBuilder {
    public let name = "FillStyle"
    public let definitions: [RuntimeBuilderDefinition]

    public init() {
        definitions = [
            RuntimeBuilderDefinition(
                parameters: [
                    RuntimeParameter(name: "eoFill", type: "Bool", defaultValue: .bool(false)),
                    RuntimeParameter(name: "antialiased", type: "Bool", defaultValue: .bool(true))
                ],
                build: { arguments, _ in
                    let eoFill = arguments.value(named: "eoFill")?.asBool ?? false
                    let antialiased = arguments.value(named: "antialiased")?.asBool ?? true
                    let style = FillStyle(eoFill: eoFill, antialiased: antialiased)
                    return .swiftUI(.fillStyle(style))
                }
            )
        ]
    }
}
