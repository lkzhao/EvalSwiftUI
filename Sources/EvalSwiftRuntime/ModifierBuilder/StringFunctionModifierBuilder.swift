import Foundation

struct StringFunctionModifierBuilder: RuntimeMethodBuilder {
    let name: String
    let definitions: [RuntimeMethodDefinition]

    init(
        name: String,
        parameters: [RuntimeParameter],
        handler: @escaping (String, [RuntimeArgument], RuntimeScope) throws -> RuntimeValue
    ) {
        self.name = name
        self.definitions = [
            RuntimeValueMethodDefinition(parameters: parameters) { base, arguments, scope in
                guard case .string(let value) = base else {
                    throw RuntimeError.invalidArgument("\(name) requires a String receiver.")
                }
                return try handler(value, arguments, scope)
            }
        ]
    }
}

extension StringFunctionModifierBuilder {
    static func contains() -> StringFunctionModifierBuilder {
        StringFunctionModifierBuilder(
            name: "contains",
            parameters: [
                RuntimeParameter(label: "_", name: "value", type: "String")
            ]
        ) { string, arguments, _ in
            guard let query = arguments.value(named: "value")?.asString else {
                throw RuntimeError.invalidArgument("contains(_:) expects a string argument.")
            }
            return .bool(string.contains(query))
        }
    }

    static func hasPrefix() -> StringFunctionModifierBuilder {
        StringFunctionModifierBuilder(
            name: "hasPrefix",
            parameters: [
                RuntimeParameter(label: "_", name: "value", type: "String")
            ]
        ) { string, arguments, _ in
            guard let prefix = arguments.value(named: "value")?.asString else {
                throw RuntimeError.invalidArgument("hasPrefix(_:) expects a string argument.")
            }
            return .bool(string.hasPrefix(prefix))
        }
    }

    static func hasSuffix() -> StringFunctionModifierBuilder {
        StringFunctionModifierBuilder(
            name: "hasSuffix",
            parameters: [
                RuntimeParameter(label: "_", name: "value", type: "String")
            ]
        ) { string, arguments, _ in
            guard let suffix = arguments.value(named: "value")?.asString else {
                throw RuntimeError.invalidArgument("hasSuffix(_:) expects a string argument.")
            }
            return .bool(string.hasSuffix(suffix))
        }
    }

    static func split() -> StringFunctionModifierBuilder {
        StringFunctionModifierBuilder(
            name: "split",
            parameters: [
                RuntimeParameter(label: "separator", name: "separator", type: "String")
            ]
        ) { string, arguments, _ in
            guard let separatorString = arguments.value(named: "separator")?.asString,
                  let separator = separatorString.first else {
                throw RuntimeError.invalidArgument("split(separator:) expects a non-empty separator string.")
            }
            let parts = string.split(separator: separator).map { RuntimeValue.string(String($0)) }
            return .array(parts)
        }
    }
}
