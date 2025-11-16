import SwiftUI

public struct TextFieldValueBuilder: RuntimeValueBuilder {
    public let name = "TextField"
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
                        throw RuntimeError.invalidArgument("TextField requires a title string.")
                    }
                    let binding = try Self.makeTextBinding(from: arguments.value(named: "text"))
                    return .swiftUI(.view(AnyView(TextField(title, text: binding))))
                }
            )
        ]
    }

    static func makeTextBinding(from value: RuntimeValue?) throws -> Binding<String> {
        guard let runtimeBinding = value?.asBinding else {
            throw RuntimeError.invalidArgument("TextField requires a Binding<String> for text.")
        }
        return Binding(
            get: {
                do {
                    return try runtimeBinding.get().asString ?? ""
                } catch {
                    assertionFailure("Failed to read binding: \(error)")
                    return ""
                }
            },
            set: { newValue in
                do {
                    try runtimeBinding.set(.string(newValue))
                } catch {
                    assertionFailure("Failed to set binding: \(error)")
                }
            }
        )
    }
}
