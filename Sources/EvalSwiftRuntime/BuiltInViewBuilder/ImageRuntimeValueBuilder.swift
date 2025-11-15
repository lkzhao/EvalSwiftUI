import SwiftUI

public struct ImageRuntimeValueBuilder: RuntimeValueBuilder {
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
                        throw RuntimeError.invalidArgument("Image expects a non-empty name.")
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
                        throw RuntimeError.invalidArgument("Image(systemName:) expects a non-empty symbol name.")
                    }
                    return .swiftUI(.view(Image(systemName: systemName)))
                }
            )
        ]
    }
}

public struct IntValueBuilder: RuntimeValueBuilder {
    public let name = "Int"

    public let definitions: [RuntimeFunctionDefinition]

    public init() {
        self.definitions = [
            RuntimeFunctionDefinition(
                parameters: [
                    RuntimeParameter(name: "value", type: "String")
                ],
                build: { arguments, _ in
                    guard let stringValue = arguments.first?.value.asString,
                          let intValue = Int(stringValue) else {
                        throw RuntimeError.invalidArgument("Int expects a valid integer string.")
                    }
                    return .int(intValue)
                }
            ),
            RuntimeFunctionDefinition(
                parameters: [
                    RuntimeParameter(name: "value", type: "Double")
                ],
                build: { arguments, _ in
                    guard let doubleValue = arguments.first?.value.asDouble else {
                        throw RuntimeError.invalidArgument("Int expects a valid double value.")
                    }
                    return .int(Int(doubleValue))
                }
            ),
            RuntimeFunctionDefinition(
                parameters: [
                    RuntimeParameter(name: "value", type: "Float")
                ],
                build: { arguments, _ in
                    guard let doubleValue = arguments.first?.value.asDouble else {
                        throw RuntimeError.invalidArgument("Int expects a valid double value.")
                    }
                    return .int(Int(doubleValue))
                }
            ),
            RuntimeFunctionDefinition(
                parameters: [
                    RuntimeParameter(name: "value", type: "CGFloat")
                ],
                build: { arguments, _ in
                    guard let doubleValue = arguments.first?.value.asDouble else {
                        throw RuntimeError.invalidArgument("Int expects a valid double value.")
                    }
                    return .int(Int(doubleValue))
                }
            ),
        ]
    }
}

struct FloatValueBuilder: RuntimeValueBuilder {
    public let name: String

    public let definitions: [RuntimeFunctionDefinition]

    public init(name: String) {
        self.name = name
        self.definitions = [
            RuntimeFunctionDefinition(
                parameters: [
                    RuntimeParameter(name: "value", type: "String")
                ],
                build: { arguments, _ in
                    guard let stringValue = arguments.first?.value.asString,
                          let floatValue = Float(stringValue) else {
                        throw RuntimeError.invalidArgument("Float expects a valid float string.")
                    }
                    return .double(Double(floatValue))
                }
            ),
            RuntimeFunctionDefinition(
                parameters: [
                    RuntimeParameter(name: "value", type: "Double")
                ],
                build: { arguments, _ in
                    guard let doubleValue = arguments.first?.value.asDouble else {
                        throw RuntimeError.invalidArgument("Float expects a valid double value.")
                    }
                    return .double(doubleValue)
                }
            ),
            RuntimeFunctionDefinition(
                parameters: [
                    RuntimeParameter(name: "value", type: "CGFloat")
                ],
                build: { arguments, _ in
                    guard let doubleValue = arguments.first?.value.asDouble else {
                        throw RuntimeError.invalidArgument("Float expects a valid double value.")
                    }
                    return .double(doubleValue)
                }
            ),
            RuntimeFunctionDefinition(
                parameters: [
                    RuntimeParameter(name: "value", type: "Int")
                ],
                build: { arguments, _ in
                    guard let intValue = arguments.first?.value.asInt else {
                        throw RuntimeError.invalidArgument("Float expects a valid int value.")
                    }
                    return .double(Double(intValue))
                }
            ),
        ]
    }
}
