import Foundation
import EvalSwiftIR

public typealias Function = FunctionIR
public typealias ViewDefinition = ViewDefinitionIR
public typealias RuntimeKeyPath = KeyPathIR

extension ViewDefinition {
    func makeInstance(
        arguments: [RuntimeArgument] = [],
        scope: RuntimeScope,
    ) throws -> RuntimeInstance {
        let instance = RuntimeInstance(parent: scope)
        for binding in bindings {
            if let initializer = binding.initializer {
                let rawValue = try ExpressionEvaluator.evaluate(initializer, scope: instance) ?? .void
                let coercedValue = binding.coercedValue(from: rawValue)
                instance.define(binding.name, value: coercedValue)
            } else {
                instance.define(binding.name, value: .void)
            }
        }
        _ = try instance.getFunction("init").invoke(arguments: arguments, scope: instance)
        return instance
    }
}

extension Function {
    func invoke(arguments: [RuntimeArgument] = [],
                scope: RuntimeScope) throws -> RuntimeValue? {
        let functionScope = RuntimeFunctionScope(parent: scope)
        let parser = ArgumentParser(parameters: parameters)
        try parser.bind(arguments: arguments, into: functionScope)
        let interpreter = StatementInterpreter(scope: functionScope)
        return try interpreter.execute(statements: body)
    }

    func renderRuntimeViews(
        arguments: [RuntimeArgument] = [],
        scope: RuntimeScope
    ) throws -> [RuntimeView] {
        let functionScope = RuntimeFunctionScope(parent: scope)
        let parser = ArgumentParser(parameters: parameters)
        try parser.bind(arguments: arguments, into: functionScope)
        let interpreter = StatementInterpreter(scope: functionScope)
        return try interpreter.executeAndCollectRuntimeViews(statements: body)
    }
}

private enum PreferredNumericType {
    case int
    case double
}

extension BindingIR {
    func coercedValue(from value: RuntimeValue) -> RuntimeValue {
        guard let preferred = preferredNumericType else {
            return value
        }

        switch preferred {
        case .double:
            if let double = value.asDouble {
                return .double(double)
            }
            return value
        case .int:
            if let int = value.asInt {
                return .int(int)
            }
            return value
        }
    }

    private var preferredNumericType: PreferredNumericType? {
        guard let annotation = typeAnnotation?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else {
            return nil
        }

        switch annotation {
        case "double":
            return .double
        case "float", "cgfloat":
            return .double
        case "int":
            return .int
        default:
            return nil
        }
    }
}
