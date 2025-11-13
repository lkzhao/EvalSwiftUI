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
                try scope.define(binding: binding)
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
            if case .identifier("self") = base {
                if let instance = scope.instance {
                    try instance.set(name, value: value)
                } else {
                    throw RuntimeError.unsupportedAssignment("self is not bound to an instance")
                }
            } else if case .identifier("Self") = base {
                if let instance = scope.type {
                    try instance.set(name, value: value)
                } else {
                    throw RuntimeError.unsupportedAssignment("Self is not bound to an Type")
                }
            } else {
                guard let baseValue = try ExpressionEvaluator.evaluate(base, scope: scope) else {
                    throw RuntimeError.unsupportedAssignment("Member assignment requires a base value")
                }

                switch baseValue {
                case .instance(let instance):
                    try instance.set(name, value: value)
                case .type(let type):
                    try type.set(name, value: value)
                default:
                    throw RuntimeError.unsupportedAssignment(
                        "Cannot assign to member '\(name)' on \(baseValue.valueTypeDescription)"
                    )
                }
            }
        default:
            throw RuntimeError.unsupportedAssignment("Unsupported assignment target")
        }
    }
}
