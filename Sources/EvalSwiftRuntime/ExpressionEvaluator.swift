import Foundation
import EvalSwiftIR

struct ExpressionEvaluator {
    let module: RuntimeModule
    let scope: RuntimeScope

    func evaluate(expression: ExprIR?) throws -> RuntimeValue? {
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
        case .view(let definition):
            let compiled = CompiledViewDefinition(ir: definition, module: module)
            return .viewDefinition(compiled)
        case .function(let functionIR):
            let compiled = CompiledFunction(ir: functionIR, module: module)
            return .function(compiled)
        case .member(let base, let name):
            let baseValue = try evaluate(expression: base)
            let description = "\(baseValue?.description ?? "nil")\(String.runtimeMemberSeparator)\(name)"
            return .string(description)
        case .call(let callee, let arguments):
            if let viewName = identifierName(from: callee) {
                let evaluatedParameters = try arguments.map { argument in
                    let value = try evaluate(expression: argument.value) ?? .void
                    return RuntimeView.Parameter(label: argument.label, value: value)
                }

                if module.builder(named: viewName) != nil || module.viewDefinition(named: viewName) != nil {
                    return .view(RuntimeView(typeName: viewName, parameters: evaluatedParameters))
                }
            }

            guard let calleeValue = try evaluate(expression: callee),
                  case .function(let compiled) = calleeValue else {
                throw RuntimeError.unsupportedExpression("Call target is not a function")
            }
            let resolvedArguments = try arguments.map { try evaluate(expression: $0.value) ?? .void }
            return try compiled.invoke(arguments: resolvedArguments, scope: scope)
        case .unknown(let raw):
            throw RuntimeError.unsupportedExpression(raw)
        }
    }

    private func identifierName(from expr: ExprIR) -> String? {
        if case .identifier(let name) = expr { return name }
        return nil
    }
}
