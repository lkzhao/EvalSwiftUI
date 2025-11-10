import Foundation
import EvalSwiftIR

final class StatementInterpreter {
    private unowned let module: RuntimeModule
    private let scope: RuntimeScope

    init(module: RuntimeModule, scope: RuntimeScope) {
        self.module = module
        self.scope = scope
    }

    func execute(statements: [StatementIR], onExpression: ((RuntimeValue) -> Void)? = nil) throws -> RuntimeValue {
        var lastExpressionValue: RuntimeValue?
        for statement in statements {
            switch statement {
            case .binding(let binding):
                let value = try module.evaluate(expression: binding.initializer, scope: scope)
                scope.define(binding.name, value: value ?? .void)
            case .expression(let expression):
                lastExpressionValue = try module.evaluate(expression: expression, scope: scope)
                if let value = lastExpressionValue {
                    onExpression?(value)
                }
            case .return(let returnStmt):
                let value = try module.evaluate(expression: returnStmt.value, scope: scope) ?? .void
                onExpression?(value)
                return value
            case .assignment(let assignment):
                let value = try module.evaluate(expression: assignment.value, scope: scope) ?? .void
                try assign(value: value, to: assignment.target)
            case .unhandled(let raw):
                throw RuntimeError.unsupportedExpression(raw)
            }
        }
        return lastExpressionValue ?? .void
    }

    private func assign(value: RuntimeValue, to target: ExprIR) throws {
        switch target {
        case .identifier(let name):
            scope.set(name, value: value)
        case .member(let base, let name):
            if case .identifier("self") = base {
                scope.set(name, value: value, preference: .preferAncestor)
            } else {
                throw RuntimeError.unsupportedAssignment("Assignments only support self member targets")
            }
        default:
            throw RuntimeError.unsupportedAssignment("Unsupported assignment target")
        }
    }
}
