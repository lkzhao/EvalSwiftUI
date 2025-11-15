import SwiftUI

public struct ImageValueBuilder: RuntimeValueBuilder {
    public let name = "Image"

    public let definitions: [RuntimeBuilderDefinition]

    public init() {
        self.definitions = [
            RuntimeBuilderDefinition(
                parameters: [
                    RuntimeParameter(label: "_", name: "name", type: "String")
                ],
                build: { arguments, _ in
                    guard let name = arguments.first?.value.asString, !name.isEmpty else {
                        throw RuntimeError.invalidArgument("Image expects a non-empty name.")
                    }
                    return .swiftUI(.view(Image(name)))
                }
            ),
            RuntimeBuilderDefinition(
                parameters: [
                    RuntimeParameter(name: "systemName", type: "String")
                ],
                build: { arguments, _ in
                    guard let systemName = arguments.first?.value.asString, !systemName.isEmpty else {
                        throw RuntimeError.invalidArgument("Image(systemName:) expects a non-empty symbol name.")
                    }
                    return .swiftUI(.view(Image(systemName: systemName)))
                }
            )
        ]
    }
}
