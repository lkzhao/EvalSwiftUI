import Foundation
import EvalSwiftIR

public final class CompiledFunction {
    public let ir: FunctionIR
    private unowned let module: RuntimeModule

    init(ir: FunctionIR, module: RuntimeModule) {
        self.ir = ir
        self.module = module
    }

    func invoke(arguments: [RuntimeParameter], scope: RuntimeScope) throws -> RuntimeValue {
        let localScope = RuntimeScope(parent: scope)

        for (index, parameter) in ir.parameters.enumerated() {
            let argument = index < arguments.count ? arguments[index].value : RuntimeValue.void
            localScope.set(parameter.name, value: argument)
        }

        let interpreter = StatementInterpreter(module: module, scope: localScope)
        return try interpreter.execute(statements: ir.body)
    }
}
