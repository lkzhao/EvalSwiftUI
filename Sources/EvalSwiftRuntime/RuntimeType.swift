import EvalSwiftIR

public final class RuntimeType: RuntimeScope {
    private var ir: DefinitionIR
    public var storage: [String: RuntimeValue] = [:]
    public var parent: RuntimeScope?

    public var name: String {
        ir.name
    }

    public init(ir: DefinitionIR, parent: RuntimeScope?) throws {
        self.ir = ir
        self.parent = parent
        for binding in ir.staticBindings {
            try define(binding: binding)
        }
    }

    public func makeInstance(arguments: [RuntimeArgument] = []) throws -> RuntimeInstance {
        let instance = RuntimeInstance(parent: self)
        for binding in ir.bindings {
            try instance.define(binding: binding)
        }
        _ = try instance.callFunction("init", arguments: arguments)
        return instance
    }
}
