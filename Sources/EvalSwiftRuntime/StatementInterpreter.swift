import Foundation
import EvalSwiftIR

final class StatementInterpreter {
    private unowned let module: RuntimeModule
    private let instance: RuntimeInstance

    init(module: RuntimeModule, instance: RuntimeInstance) {
        self.module = module
        self.instance = instance
    }

    func execute(statements: [StatementIR], onExpression: ((RuntimeValue) -> Void)? = nil) throws -> RuntimeValue {
        var lastExpressionValue: RuntimeValue?
        for statement in statements {
            switch statement {
            case .binding(let binding):
                let value = try module.evaluate(expression: binding.initializer, instance: instance)
                instance.define(binding.name, value: value ?? .void)
            case .expression(let expression):
                lastExpressionValue = try module.evaluate(expression: expression, instance: instance)
                if let value = lastExpressionValue {
                    onExpression?(value)
                }
            case .return(let returnStmt):
                let value = try module.evaluate(expression: returnStmt.value, instance: instance) ?? .void
                onExpression?(value)
                return value
            case .assignment(let assignment):
                let value = try module.evaluate(expression: assignment.value, instance: instance) ?? .void
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
            instance.set(name, value: value)
        case .member(let base, let name):
            if case .identifier("self") = base {
                instance.set(name, value: value, preference: .preferAncestor)
            } else {
                throw RuntimeError.unsupportedAssignment("Assignments only support self member targets")
            }
        default:
            throw RuntimeError.unsupportedAssignment("Unsupported assignment target")
        }
    }
}
