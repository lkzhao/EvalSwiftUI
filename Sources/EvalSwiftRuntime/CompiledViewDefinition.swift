import Foundation
import EvalSwiftIR

public final class CompiledViewDefinition {
    public let ir: ViewDefinitionIR
    private unowned let module: RuntimeModule

    init(ir: ViewDefinitionIR, module: RuntimeModule) {
        self.ir = ir
        self.module = module
    }

    func makeInstance(
        arguments: [RuntimeArgument],
        scope: RuntimeScope,
    ) throws -> RuntimeInstance {
        let instance = RuntimeInstance(parent: scope)
        for binding in ir.bindings {
            if let initializer = binding.initializer {
                let value = try ExpressionEvaluator.evaluate(initializer, module: module, scope: instance) ?? .void
                instance.define(binding.name, value: value)
            } else {
                instance.define(binding.name, value: .void)
            }
        }
        _ = try instance.callMethod("init", arguments: arguments)
        return instance
    }
}
