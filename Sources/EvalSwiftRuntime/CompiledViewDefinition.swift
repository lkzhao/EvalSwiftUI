import Foundation
import EvalSwiftIR

public final class CompiledViewDefinition {
    public let ir: ViewDefinitionIR
    private unowned let module: RuntimeModule

    init(ir: ViewDefinitionIR, module: RuntimeModule) {
        self.ir = ir
        self.module = module
    }

    public func instantiate(scope: RuntimeScope, parameters: [RuntimeView.Parameter] = []) throws -> RuntimeValue {
        let localScope = RuntimeScope(parent: scope)
        try initializeBindings(in: localScope)
        let interpreter = StatementInterpreter(module: module, scope: localScope)
        return try interpreter.execute(statements: ir.body)
    }

    private func initializeBindings(in localScope: RuntimeScope) throws {
        for binding in ir.bindings {
            guard let initializer = binding.initializer else { continue }
            let value = try module.evaluate(expression: initializer, scope: localScope) ?? .void
            localScope.set(binding.name, value: value)
        }
    }
}
