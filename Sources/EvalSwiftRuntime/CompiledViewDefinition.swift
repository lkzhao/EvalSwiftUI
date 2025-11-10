import Foundation
import EvalSwiftIR

public final class CompiledViewDefinition {
    public let ir: ViewDefinitionIR
    private unowned let module: RuntimeModule
    private let parameters: [FunctionParameterIR]

    init(ir: ViewDefinitionIR, module: RuntimeModule) {
        self.ir = ir
        self.module = module
        self.parameters = CompiledViewDefinition.makeParameters(from: ir.bindings)
    }

    public func instantiate(scope: RuntimeScope, parameters: [RuntimeParameter] = []) throws -> RuntimeValue {
        let localScope = RuntimeScope(parent: scope)
        try initializeBindings(in: localScope, arguments: parameters)
        let interpreter = StatementInterpreter(module: module, scope: localScope)
        return try interpreter.execute(statements: ir.body)
    }

    private func initializeBindings(in localScope: RuntimeScope, arguments: [RuntimeParameter]) throws {
        let parser = ArgumentParser(parameters: parameters)
        let parameterNames = Set(parameters.map { $0.name })

        try parser.bind(arguments: arguments, into: localScope, module: module)

        for binding in ir.bindings where !parameterNames.contains(binding.name) {
            guard let initializer = binding.initializer else { continue }
            let value = try module.evaluate(expression: initializer, scope: localScope) ?? .void
            localScope.set(binding.name, value: value)
        }
    }

    private static func makeParameters(from bindings: [BindingIR]) -> [FunctionParameterIR] {
        bindings.compactMap { binding in
            guard !binding.isFunctionBinding else { return nil }
            return FunctionParameterIR(label: binding.name, name: binding.name, defaultValue: binding.initializer)
        }
    }
}

private extension BindingIR {
    var isFunctionBinding: Bool {
        if case .some(.function) = initializer {
            return true
        }
        return false
    }
}
