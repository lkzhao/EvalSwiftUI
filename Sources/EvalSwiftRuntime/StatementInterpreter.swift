import Foundation
import EvalSwiftIR

final class StatementInterpreter {
    private unowned let module: RuntimeModule
    private let scope: RuntimeScope

    init(module: RuntimeModule, scope: RuntimeScope) {
        self.module = module
        self.scope = scope
    }

    func execute(statements: [StatementIR]) throws -> RuntimeValue {
        var lastExpressionValue: RuntimeValue?
        for statement in statements {
            switch statement {
            case .binding(let binding):
                let value = try module.evaluate(expression: binding.initializer, scope: scope)
                scope.set(binding.name, value: value ?? .void)
            case .expression(let expression):
                lastExpressionValue = try module.evaluate(expression: expression, scope: scope)
            case .return(let returnStmt):
                return try module.evaluate(expression: returnStmt.value, scope: scope) ?? .void
            case .unhandled(let raw):
                throw RuntimeError.unsupportedExpression(raw)
            }
        }
        return lastExpressionValue ?? .void
    }
}
