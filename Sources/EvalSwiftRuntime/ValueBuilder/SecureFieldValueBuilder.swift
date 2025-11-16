import SwiftUI

public struct SecureFieldValueBuilder: RuntimeValueBuilder {
    public let name = "SecureField"
    public let definitions: [RuntimeBuilderDefinition]

    public init() {
        definitions = [
            RuntimeBuilderDefinition(
                parameters: [
                    RuntimeParameter(label: "_", name: "title", type: "String"),
                    RuntimeParameter(name: "text", type: "Binding<String>")
                ],
                build: { arguments, _ in
                    guard let title = arguments.value(named: "title")?.asString else {
                        throw RuntimeError.invalidArgument("SecureField requires a title string.")
                    }
                    let binding = try TextFieldValueBuilder.makeTextBinding(from: arguments.value(named: "text"))
                    return .swiftUI(.view(AnyView(SecureField(title, text: binding))))
                }
            )
        ]
    }
}
