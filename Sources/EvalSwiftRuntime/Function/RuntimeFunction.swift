import EvalSwiftIR
import SwiftUI

public class RuntimeFunctionScope: RuntimeScope {
    public var storage: RuntimeScopeStorage = [:]
    public var parent: RuntimeScope?

    init(parent: RuntimeScope) {
        self.parent = parent
    }
}

public final class RuntimeFunction {
    var parameters: [RuntimeParameter]
    var statements: [StatementIR]
    var parent: RuntimeScope

    public init(ir: FunctionIR, parent: RuntimeScope) throws {
        self.parameters = try ir.parameters.map {
            try RuntimeParameter(ir: $0, scope: parent)
        }
        self.parent = parent
        self.statements = ir.body
    }

    public func invoke(arguments: [RuntimeArgument] = []) throws -> RuntimeValue? {
        let scope = RuntimeFunctionScope(parent: parent)
        for argument in arguments {
            scope.define(argument.name, value: argument.value)
        }
        let interpreter = StatementInterpreter(scope: scope)
        return try interpreter.execute(statements: statements)
    }

    public func renderRuntimeViews(arguments: [RuntimeArgument] = []) throws -> [RuntimeValue] {
        let scope = RuntimeFunctionScope(parent: parent)
        for argument in arguments {
            scope.define(argument.name, value: argument.value)
        }
        let interpreter = StatementInterpreter(scope: scope)
        return try interpreter.executeAndCollectTopLevelValues(statements: statements)
    }
}
