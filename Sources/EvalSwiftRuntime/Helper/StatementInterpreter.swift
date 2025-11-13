import Foundation
import EvalSwiftIR
import SwiftUI

final class StatementInterpreter {
    private let scope: RuntimeScope
    private var collectedValues: [RuntimeValue] = []

    init(scope: RuntimeScope) {
        self.scope = scope
    }

    func execute(statements: [StatementIR]) throws -> RuntimeValue? {
        for statement in statements {
            switch statement {
            case .binding(let binding):
                let value = try ExpressionEvaluator.evaluate(binding.initializer, scope: scope)
                let storedValue = binding.coercedValue(from: value ?? .void)
                scope.define(binding.name, value: storedValue)
            case .expression(let expression):
                let value = try ExpressionEvaluator.evaluate(expression, scope: scope)
                if let value {
                    collectedValues.append(value)
                }
            case .return(let returnStmt):
                let value = try ExpressionEvaluator.evaluate(returnStmt.value, scope: scope)
                if let value {
                    collectedValues.append(value)
                }
                return value
            case .assignment(let assignment):
                let value = try ExpressionEvaluator.evaluate(assignment.value, scope: scope) ?? .void
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

    func executeAndCollectRuntimeViews(statements: [StatementIR]) throws -> [RuntimeInstance] {
        try executeAndCollectResultBuilderValues(statements: statements).compactMap {
            if case .instance(let instance) = $0 {
                return instance
            }
            return nil
        }
    }

    private func assign(value: RuntimeValue, to target: ExprIR) throws {
        switch target {
        case .identifier(let name):
            try scope.set(name, value: value)
        case .member(let base, let name):
            if case .identifier("self") = base, let instance = scope.instance {
                try instance.set(name, value: value)
            } else {
                throw RuntimeError.unsupportedAssignment("Assignments only support self member targets")
            }
        default:
            throw RuntimeError.unsupportedAssignment("Unsupported assignment target")
        }
    }
}
