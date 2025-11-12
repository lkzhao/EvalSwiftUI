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
        parentInstance: RuntimeInstance,
        parameters: [RuntimeParameter]
    ) throws -> RuntimeInstance {
        let localInstance = RuntimeInstance(parent: parentInstance)
        for binding in ir.bindings {
            if let initializer = binding.initializer {
                let value = try module.evaluate(expression: initializer, instance: localInstance) ?? .void
                localInstance.set(binding.name, value: value)
            } else {
                localInstance.set(binding.name, value: .void)
            }
        }
        _ = try localInstance.callMethod("init", arguments: parameters)
        return localInstance
    }
}
