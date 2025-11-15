//
//  FloatValueBuilder.swift
//  EvalSwiftUI
//
//  Created by Luke Zhao on 11/14/25.
//



struct FloatValueBuilder: RuntimeValueBuilder {
    public let name: String

    public let definitions: [RuntimeBuilderDefinition] = [
        RuntimeBuilderDefinition(
            parameters: [
                RuntimeParameter(label: "_", name: "value", type: "String")
            ],
            build: { arguments, _ in
                guard let stringValue = arguments.first?.value.asString,
                      let floatValue = Float(stringValue) else {
                    throw RuntimeError.invalidArgument("Float expects a valid float string.")
                }
                return .double(Double(floatValue))
            }
        ),
        RuntimeBuilderDefinition(
            parameters: [
                RuntimeParameter(label: "_", name: "value", type: "Double")
            ],
            build: { arguments, _ in
                guard let doubleValue = arguments.first?.value.asDouble else {
                    throw RuntimeError.invalidArgument("Float expects a valid double value.")
                }
                return .double(doubleValue)
            }
        ),
        RuntimeBuilderDefinition(
            parameters: [
                RuntimeParameter(label: "_", name: "value", type: "CGFloat")
            ],
            build: { arguments, _ in
                guard let doubleValue = arguments.first?.value.asDouble else {
                    throw RuntimeError.invalidArgument("Float expects a valid double value.")
                }
                return .double(doubleValue)
            }
        ),
        RuntimeBuilderDefinition(
            parameters: [
                RuntimeParameter(label: "_", name: "value", type: "Int")
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
