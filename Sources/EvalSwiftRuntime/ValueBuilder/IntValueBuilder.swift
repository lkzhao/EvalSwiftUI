//
//  IntValueBuilder.swift
//  EvalSwiftUI
//
//  Created by Luke Zhao on 11/14/25.
//



public struct IntValueBuilder: RuntimeValueBuilder {
    public let name = "Int"

    public let definitions: [RuntimeBuilderDefinition] = [
        RuntimeBuilderDefinition(
            parameters: [
                RuntimeParameter(label: "_", name: "value", type: "String")
            ],
            build: { arguments, _ in
                guard let stringValue = arguments.value(named: "value")?.asString,
                      let intValue = Int(stringValue) else {
                    throw RuntimeError.invalidArgument("Int expects a valid integer string.")
                }
                return .int(intValue)
            }
        ),
        RuntimeBuilderDefinition(
            parameters: [
                RuntimeParameter(label: "_", name: "value", type: "Double")
            ],
            build: { arguments, _ in
                guard let doubleValue = arguments.value(named: "value")?.asDouble else {
                    throw RuntimeError.invalidArgument("Int expects a valid double value.")
                }
                return .int(Int(doubleValue))
            }
        ),
        RuntimeBuilderDefinition(
            parameters: [
                RuntimeParameter(label: "_", name: "value", type: "Float")
            ],
            build: { arguments, _ in
                guard let doubleValue = arguments.value(named: "value")?.asDouble else {
                    throw RuntimeError.invalidArgument("Int expects a valid double value.")
                }
                return .int(Int(doubleValue))
            }
        ),
        RuntimeBuilderDefinition(
            parameters: [
                RuntimeParameter(label: "_", name: "value", type: "CGFloat")
            ],
            build: { arguments, _ in
                guard let doubleValue = arguments.value(named: "value")?.asDouble else {
                    throw RuntimeError.invalidArgument("Int expects a valid double value.")
                }
                return .int(Int(doubleValue))
            }
        ),
    ]
}
