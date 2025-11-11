import Foundation
import EvalSwiftIR

public final class CompiledViewDefinition {
    public let ir: ViewDefinitionIR
    private unowned let module: RuntimeModule

    init(ir: ViewDefinitionIR, module: RuntimeModule) {
        self.ir = ir
        self.module = module
    }

    func makeInstanceScope(
        parentScope: RuntimeScope,
        parameters: [RuntimeParameter]
    ) throws -> RuntimeScope {
        let localScope = RuntimeScope(parent: parentScope)
        try initializeInstanceBindings(in: localScope)
        try runInitializer(in: localScope, arguments: parameters)
        return localScope
    }

    func renderBody(in scope: RuntimeScope) throws -> RuntimeValue {
        guard let bodyValue = scope.get("body"), case .function(let bodyFunction) = bodyValue else {
            throw RuntimeError.unsupportedExpression("View definitions must provide a body")
        }
        return try bodyFunction.invoke(arguments: [], scope: scope)
    }

    private func runInitializer(in scope: RuntimeScope, arguments: [RuntimeParameter]) throws {
        guard case .function(let initializer) = scope.get("init") else {
            throw RuntimeError.unsupportedExpression("View definitions must provide an init")
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
