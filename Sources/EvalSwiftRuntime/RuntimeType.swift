import EvalSwiftIR

public final class RuntimeType: RuntimeScope {
    private var ir: DefinitionIR
    public var storage: [String: RuntimeValue] = [:]
    public weak var parent: RuntimeScope?

    public var name: String {
        ir.name
    }

    public init(ir: DefinitionIR, parent: RuntimeScope?) {
        self.ir = ir
        self.parent = parent
    }

    public func makeInstance(arguments: [RuntimeArgument] = []) throws -> RuntimeInstance {
        let instance = RuntimeInstance(parent: self)
        for binding in ir.bindings {
            if let initializer = binding.initializer {
                let rawValue = try ExpressionEvaluator.evaluate(initializer, scope: instance) ?? .void
                let coercedValue = binding.coercedValue(from: rawValue)
                instance.define(binding.name, value: coercedValue)
            } else {
                instance.define(binding.name, value: .void)
            }
        }
        _ = try instance.callFunction("init", arguments: arguments)
        return instance
    }
}
