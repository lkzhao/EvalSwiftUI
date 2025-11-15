import Foundation

public struct UUIDValueBuilder: RuntimeValueBuilder {
    public let name = "UUID"
    public let definitions: [RuntimeBuilderDefinition]

    public init() {
        definitions = [
            RuntimeBuilderDefinition(parameters: []) { _, _ in
                .uuid(UUID())
            },
            RuntimeBuilderDefinition(
                parameters: [
                    RuntimeParameter(label: "uuidString", name: "uuidString", type: "String")
                ],
                build: { arguments, _ in
                    guard let uuidString = arguments.value(named: "uuidString")?.asString,
                          let uuid = UUID(uuidString: uuidString) else {
                        return .void
                    }
                    return .uuid(uuid)
                }
            )
        ]
    }
}
