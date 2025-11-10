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
        let parser = ArgumentParser(parameters: ir.parameters)
        try parser.bind(arguments: arguments, into: localScope, module: module)

        let interpreter = StatementInterpreter(module: module, scope: localScope)
        return try interpreter.execute(statements: ir.body)
    }
}
