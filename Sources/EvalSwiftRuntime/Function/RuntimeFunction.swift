import EvalSwiftIR
import SwiftUI

public final class RuntimeFunction: RuntimeScope {
    public var storage: RuntimeScopeStorage = [:]
    public var parent: RuntimeScope?

    public enum Content {
        case definition(FunctionIR)
        case builtIn(RuntimeBuiltInFunction)

        var parameters: [RuntimeParameter] {
            switch self {
            case .definition(let ir):
                return ir.parameters
            case .builtIn(let builtIn):
                return builtIn.parameters
            }
        }
    }

    public var content: Content

    public init(ir: FunctionIR, parent: RuntimeScope?) {
        self.content = .definition(ir)
        self.parent = parent
    }

    public init(builtInFunction: RuntimeBuiltInFunction, parent: RuntimeScope?) {
        self.content = .builtIn(builtInFunction)
        self.parent = parent
    }

    public var parameters: [RuntimeParameter] {
        content.parameters
    }

    public func invoke(arguments: [RuntimeArgument] = []) throws -> RuntimeValue? {
        storage.removeAll()
        switch content {
        case .definition(let ir):
            for argument in arguments {
                define(argument.name, value: argument.value)
            }
            let interpreter = StatementInterpreter(scope: self)
            return try interpreter.execute(statements: ir.body)
        case .builtIn(let function):
            return try function.call(arguments: arguments, scope: self)
        }
    }

    public func renderRuntimeViews(arguments: [RuntimeArgument] = []) throws -> [RuntimeInstance] {
        storage.removeAll()
        switch content {
        case .definition(let ir):
            for argument in arguments {
                define(argument.name, value: argument.value)
            }
            let interpreter = StatementInterpreter(scope: self)
            return try interpreter.executeAndCollectRuntimeViews(statements: ir.body)
        case .builtIn:
            throw RuntimeError.unknownFunction("Rendering views is not supported for built-in functions.")
        }
    }
}
