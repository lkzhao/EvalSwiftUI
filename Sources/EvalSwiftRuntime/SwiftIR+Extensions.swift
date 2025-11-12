import Foundation
import EvalSwiftIR

public typealias Function = FunctionIR
public typealias ViewDefinition = ViewDefinitionIR

extension ViewDefinition {
    func makeInstance(
        arguments: [RuntimeArgument],
        module: RuntimeModule,
        scope: RuntimeScope? = nil,
    ) throws -> RuntimeInstance {
        let instance = RuntimeInstance(parent: scope ?? module.globalScope)
        for binding in bindings {
            if let initializer = binding.initializer {
                let value = try ExpressionEvaluator.evaluate(initializer, module: module, scope: instance) ?? .void
                instance.define(binding.name, value: value)
            } else {
                instance.define(binding.name, value: .void)
            }
        }
        _ = try instance.callMethod("init", arguments: arguments, module: module)
        return instance
    }
}

extension Function {
    func invoke(arguments: [RuntimeArgument],
                module: RuntimeModule,
                scope: RuntimeScope? = nil) throws -> RuntimeValue? {
        let functionScope = RuntimeFunctionScope(parent: scope ?? module.globalScope)
        let parser = ArgumentParser(parameters: parameters)
        try parser.bind(arguments: arguments, into: functionScope, module: module)
        let interpreter = StatementInterpreter(module: module, scope: functionScope)
        return try interpreter.execute(statements: body)
    }
}
