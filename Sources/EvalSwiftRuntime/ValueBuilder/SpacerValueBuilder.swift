import SwiftUI

public struct SpacerValueBuilder: RuntimeValueBuilder {
    public let name = "Spacer"
    public let definitions: [RuntimeBuilderDefinition]

    public init() {
        definitions = [
            RuntimeBuilderDefinition(
                parameters: [
                    RuntimeParameter(name: "minLength", type: "Double", defaultValue: .void)
                ],
                build: { arguments, _ in
                    let minLength = arguments.value(named: "minLength")?.asCGFloat
                    let spacer: Spacer
                    if let minLength {
                        spacer = Spacer(minLength: minLength)
                    } else {
                        spacer = Spacer()
                    }
                    return .swiftUI(.view(AnyView(spacer)))
                }
            )
        ]
    }
}
