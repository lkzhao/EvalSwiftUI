import Foundation
import EvalSwiftIR

final class StatementInterpreter {
    private unowned let module: RuntimeModule
    private let scope: RuntimeScope
    private var collectedValues: [RuntimeValue] = []

    init(module: RuntimeModule, scope: RuntimeScope) {
        self.module = module
        self.scope = scope
    }

    func execute(statements: [StatementIR]) throws -> RuntimeValue? {
        for statement in statements {
            switch statement {
            case .binding(let binding):
                let value = try ExpressionEvaluator.evaluate(binding.initializer, module: module, scope: scope)
                scope.define(binding.name, value: value ?? .void)
            case .expression(let expression):
                let value = try ExpressionEvaluator.evaluate(expression, module: module, scope: scope)
                if let value {
                    collectedValues.append(value)
                }
            case .return(let returnStmt):
                let value = try ExpressionEvaluator.evaluate(returnStmt.value, module: module, scope: scope)
                if let value {
                    collectedValues.append(value)
                }
                return value
            case .assignment(let assignment):
                let value = try ExpressionEvaluator.evaluate(assignment.value, module: module, scope: scope) ?? .void
                try assign(value: value, to: assignment.target)
            case .unhandled(let raw):
                throw RuntimeError.unsupportedExpression(raw)
            }
        }
        return collectedValues.last
    }

    func executeAndCollectResultBuilderValues(statements: [StatementIR]) throws -> [RuntimeValue] {
        collectedValues = []
        _ = try execute(statements: statements)
        return collectedValues
    }

    func executeAndCollectRuntimeViews(statements: [StatementIR]) throws -> [RuntimeView] {
        try executeAndCollectResultBuilderValues(statements: statements).compactMap {
            if case .view(let runtimeView) = $0 {
                return runtimeView
            }
            return nil
        }
    }

    private func assign(value: RuntimeValue, to target: ExprIR) throws {
        switch target {
        case .identifier(let name):
            scope.set(name, value: value)
        case .member(let base, let name):
            if case .identifier("self") = base, let instance = scope.instance {
                instance.set(name, value: value)
            } else {
                throw RuntimeError.unsupportedAssignment("Assignments only support self member targets")
            }
        default:
            throw RuntimeError.unsupportedAssignment("Unsupported assignment target")
        }
    }
}
