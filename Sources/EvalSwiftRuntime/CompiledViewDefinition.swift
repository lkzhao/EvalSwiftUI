import Foundation
import EvalSwiftIR

public final class CompiledViewDefinition {
    public let ir: ViewDefinitionIR
    private unowned let module: RuntimeModule

    init(ir: ViewDefinitionIR, module: RuntimeModule) {
        self.ir = ir
        self.module = module
    }

    public func instantiate(scope: RuntimeScope, parameters: [RuntimeParameter] = []) throws -> RuntimeValue {
        let localScope = RuntimeScope(parent: scope)
        try initializeInstanceBindings(in: localScope)
        try runInitializer(in: localScope, arguments: parameters)
        guard let bodyValue = localScope.get("body"), case .function(let bodyFunction) =  bodyValue else {
            throw RuntimeError.unsupportedExpression("View definitions must provide a body binding")
        }
        return try bodyFunction.invoke(arguments: [], scope: localScope)
    }

    private func runInitializer(in scope: RuntimeScope, arguments: [RuntimeParameter]) throws {
        guard case .function(let initializer) = scope.get("init") else {
            throw RuntimeError.noInitializer
        }
        _ = try initializer.invoke(arguments: arguments, scope: scope)
    }

    private func initializeInstanceBindings(in scope: RuntimeScope) throws {
        for binding in ir.bindings {
            if let initializer = binding.initializer {
                let value = try module.evaluate(expression: initializer, scope: scope) ?? .void
                scope.set(binding.name, value: value)
            } else {
                scope.set(binding.name, value: .void)
            }
        }
    }
}
