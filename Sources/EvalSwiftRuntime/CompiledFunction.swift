import Foundation
import EvalSwiftIR

public final class CompiledFunction {
    public let ir: FunctionIR
    private unowned let module: RuntimeModule

    init(ir: FunctionIR, module: RuntimeModule) {
        self.ir = ir
        self.module = module
    }

    func invoke(arguments: [RuntimeArgument], scope: RuntimeScope) throws -> RuntimeValue {
        let functionScope = RuntimeFunctionScope(parent: scope)
        let parser = ArgumentParser(parameters: ir.parameters)
        try parser.bind(arguments: arguments, into: functionScope, module: module)

        let interpreter = StatementInterpreter(module: module, scope: functionScope)
        return try interpreter.execute(statements: ir.body)
    }
}
