import EvalSwiftIR
import SwiftUI

public final class RuntimeFunction: RuntimeScope {
    private var ir: FunctionIR
    public var storage: [String: RuntimeValue] = [:]
    public var parent: RuntimeScope?

    public init(ir: FunctionIR, parent: RuntimeScope?) {
        self.ir = ir
        self.parent = parent
    }

    public var parameters: [FunctionParameterIR] {
        ir.parameters
    }

    public func invoke(arguments: [RuntimeArgument] = []) throws -> RuntimeValue? {
        storage.removeAll()
        let parser = ArgumentParser(parameters: ir.parameters)
        try parser.bind(arguments: arguments, into: self)
        let interpreter = StatementInterpreter(scope: self)
        return try interpreter.execute(statements: ir.body)
    }

    public func renderRuntimeViews(arguments: [RuntimeArgument] = []) throws -> [RuntimeInstance] {
        storage.removeAll()
        let parser = ArgumentParser(parameters: ir.parameters)
        try parser.bind(arguments: arguments, into: self)
        let interpreter = StatementInterpreter(scope: self)
        return try interpreter.executeAndCollectRuntimeViews(statements: ir.body)
    }
}
