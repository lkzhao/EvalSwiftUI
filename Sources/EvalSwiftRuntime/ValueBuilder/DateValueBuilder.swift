import Foundation

public struct DateValueBuilder: RuntimeValueBuilder {
    public let name = "Date"
    public let definitions: [RuntimeBuilderDefinition]

    public init() {
        definitions = [
            RuntimeBuilderDefinition(parameters: []) { _, _ in
                .date(Date())
            },
            RuntimeBuilderDefinition(
                parameters: [
                    RuntimeParameter(name: "timeIntervalSince1970", type: "Double")
                ],
                build: { arguments, _ in
                    guard let interval = arguments.value(named: "timeIntervalSince1970")?.asDouble else {
                        throw RuntimeError.invalidArgument("Date(timeIntervalSince1970:) expects a Double.")
                    }
                    return .date(Date(timeIntervalSince1970: interval))
                }
            )
        ]
    }
}
