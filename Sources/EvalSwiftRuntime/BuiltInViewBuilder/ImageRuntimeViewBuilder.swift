import SwiftUI

public struct ImageRuntimeViewBuilder: RuntimeValueBuilder {
    public let name = "Image"

    public let definitions: [RuntimeFunctionDefinition]

    public init() {
        self.definitions = [
            RuntimeFunctionDefinition(
                parameters: [
                    RuntimeParameter(name: "name", type: "String")
                ],
                build: { arguments, _ in
                    guard let name = arguments.first?.value.asString, !name.isEmpty else {
                        throw RuntimeError.invalidViewArgument("Image expects a non-empty name.")
                    }
                    return .swiftUI(.view(Image(name)))
                }
            ),
            RuntimeFunctionDefinition(
                parameters: [
                    RuntimeParameter(label: "systemName", name: "systemName", type: "String")
                ],
                build: { arguments, _ in
                    guard let systemName = arguments.first?.value.asString, !systemName.isEmpty else {
                        throw RuntimeError.invalidViewArgument("Image(systemName:) expects a non-empty symbol name.")
                    }
                    return .swiftUI(.view(Image(systemName: systemName)))
                }
            )
        ]
    }
}
