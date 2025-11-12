import Foundation
import EvalSwiftIR

public final class CompiledFunction {
    public let ir: FunctionIR
    private unowned let module: RuntimeModule

    init(ir: FunctionIR, module: RuntimeModule) {
        self.ir = ir
        self.module = module
    }

    func invoke(arguments: [RuntimeParameter], instance: RuntimeInstance) throws -> RuntimeValue {
        let localInstance = RuntimeInstance(parent: instance)
        let parser = ArgumentParser(parameters: ir.parameters)
        try parser.bind(arguments: arguments, into: localInstance, module: module)

        let interpreter = StatementInterpreter(module: module, instance: localInstance)
        return try interpreter.execute(statements: ir.body)
    }
}
