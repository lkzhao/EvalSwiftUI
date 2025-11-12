import Foundation
import EvalSwiftIR

struct ExpressionEvaluator {
    static func evaluate(_ expression: ExprIR?, module: RuntimeModule, scope: RuntimeScope) throws -> RuntimeValue? {
        guard let expression else { return nil }
        switch expression {
        case .identifier(let name):
            if let local = scope.get(name) {
                return local
            }
            throw RuntimeError.unknownIdentifier(name)
        case .literal(let raw):
            if let number = Double(raw) {
                return .number(number)
            }
            if raw == "true" { return .bool(true) }
            if raw == "false" { return .bool(false) }
            if raw.hasPrefix("[") && raw.hasSuffix("]") {
                let trimmed = raw.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
                let elements = trimmed.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
                let values = elements.map { RuntimeValue.string($0.trimmingCharacters(in: CharacterSet(charactersIn: "\""))) }
                return .array(values)
            }
            return .string(raw.trimmingCharacters(in: CharacterSet(charactersIn: "\"")))
        case .stringInterpolation(let segments):
            let resolved = try segments.map { segment -> String in
                switch segment {
                case .literal(let literal):
                    return literal
                case .expression(let expr):
                    guard let value = try evaluate(expr, module: module, scope: scope) else {
                        return ""
                    }
                    return stringValue(from: value)
                }
            }.joined()
            return .string(resolved)
        case .view(let definition):
            let compiled = CompiledViewDefinition(ir: definition, module: module)
            return .viewDefinition(compiled)
        case .function(let functionIR):
            let compiled = CompiledFunction(ir: functionIR, module: module)
            return .function(compiled)
        case .member(let base, let name):
            if case .identifier("self") = base {
                if let value = scope.instance?.get(name) {
                    return value
                }
                throw RuntimeError.unknownIdentifier(name)
            }
            let baseValue = try evaluate(base, module: module, scope: scope)
            let description = "\(baseValue?.description ?? "nil")\(String.runtimeMemberSeparator)\(name)"
            return .string(description)
        case .call(let callee, let arguments):
            if let viewName = identifierName(from: callee) {
                let evaluatedArguments = try arguments.map { argument in
                    let value = try evaluate(argument.value, module: module, scope: scope) ?? .void
                    return RuntimeArgument(label: argument.label, value: value)
                }

                if module.builder(named: viewName) != nil || module.viewDefinition(named: viewName) != nil {
                    return .view(RuntimeView(typeName: viewName, arguments: evaluatedArguments))
                }
            }

            guard let calleeValue = try evaluate(callee, module: module, scope: scope),
                  case .function(let compiled) = calleeValue else {
                throw RuntimeError.unsupportedExpression("Call target is not a function")
            }
            let resolvedArguments = try arguments.map { argument in
                let value = try evaluate(argument.value, module: module, scope: scope) ?? .void
                return RuntimeArgument(label: argument.label, value: value)
            }
            return try compiled.invoke(arguments: resolvedArguments, scope: scope)
        case .unknown(let raw):
            throw RuntimeError.unsupportedExpression(raw)
        }
    }

    private static func identifierName(from expr: ExprIR) -> String? {
        if case .identifier(let name) = expr { return name }
        return nil
    }

    private static func stringValue(from value: RuntimeValue) -> String {
        if let string = value.asString {
            return string
        }
        return value.description
    }
}
