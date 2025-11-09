import Foundation
import EvalSwiftIR

public final class CompiledFunction {
    public let ir: FunctionIR
    private unowned let module: RuntimeModule

    init(ir: FunctionIR, module: RuntimeModule) {
        self.ir = ir
        self.module = module
    }

    func invoke(arguments: [RuntimeValue], scope: RuntimeScope? = nil) throws -> RuntimeValue {
        let frame = RuntimeScope(parent: scope ?? module.globals)

        for (index, parameter) in ir.parameters.enumerated() {
            let argument = index < arguments.count ? arguments[index] : RuntimeValue.void
            frame.set(parameter.internalName, value: argument)
        }

        let interpreter = StatementInterpreter(module: module, scope: frame)
        return try interpreter.execute(statements: ir.body)
    }
}
