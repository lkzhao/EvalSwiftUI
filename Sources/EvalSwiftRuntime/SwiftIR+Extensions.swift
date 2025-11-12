import Foundation
import EvalSwiftIR

public typealias Function = FunctionIR
public typealias ViewDefinition = ViewDefinitionIR

extension ViewDefinition {
    func makeInstance(
        arguments: [RuntimeArgument],
        scope: RuntimeScope,
    ) throws -> RuntimeInstance {
        let instance = RuntimeInstance(parent: scope)
        for binding in bindings {
            if let initializer = binding.initializer {
                let value = try ExpressionEvaluator.evaluate(initializer, scope: instance) ?? .void
                instance.define(binding.name, value: value)
            } else {
                instance.define(binding.name, value: .void)
            }
        }
        _ = try instance.callMethod("init", arguments: arguments)
        return instance
    }
}

extension Function {
    func invoke(arguments: [RuntimeArgument],
                scope: RuntimeScope) throws -> RuntimeValue? {
        let functionScope = RuntimeFunctionScope(parent: scope)
        let parser = ArgumentParser(parameters: parameters)
        try parser.bind(arguments: arguments, into: functionScope)
        let interpreter = StatementInterpreter(scope: functionScope)
        return try interpreter.execute(statements: body)
    }
}
