import Foundation
import EvalSwiftIR
import SwiftUI

final class StatementInterpreter {
    private let rootScope: RuntimeScope
    private var collectedValues: [RuntimeValue] = []

    init(scope: RuntimeScope) {
        self.rootScope = scope
    }

    func execute(statements: [StatementIR]) throws -> RuntimeValue? {
        collectedValues = []
        let result = try executeBlock(statements, scope: rootScope)
        if case .return(let value) = result {
            return value
        }
        return collectedValues.last
    }

    func executeAndCollectTopLevelValues(statements: [StatementIR]) throws -> [RuntimeValue] {
        collectedValues = []
        _ = try executeBlock(statements, scope: rootScope)
        return collectedValues
    }

    private enum ExecutionResult {
        case `continue`
        case `return`(RuntimeValue?)
    }

    private func executeBlock(_ statements: [StatementIR], scope: RuntimeScope) throws -> ExecutionResult {
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
                return .return(value)
            case .assignment(let assignment):
                let value = try ExpressionEvaluator.evaluate(assignment.value, scope: scope) ?? .void
                try assign(value: value, to: assignment.target, scope: scope)
            case .if(let ifStmt):
                let evaluation = try evaluate(condition: ifStmt.condition, scope: scope)
                if evaluation.passed {
                    let branchScope = evaluation.scope ?? scope
                    let result = try executeBlock(ifStmt.body, scope: branchScope)
                    if case .return = result {
                        return result
                    }
                } else if let elseBody = ifStmt.elseBody {
                    let result = try executeBlock(elseBody, scope: scope)
                    if case .return = result {
                        return result
                    }
                }
            case .unhandled(let raw):
                throw RuntimeError.unsupportedExpression(raw)
            case .guard(let guardStmt):
                let passed = try evaluateGuardConditions(guardStmt.conditions, scope: scope)
                if !passed {
                    let result = try executeBlock(guardStmt.elseBody, scope: scope)
                    if case .return(let value) = result {
                        return .return(value)
                    }
                    return .return(nil)
                }
            }
        }
        return .continue
    }

    private func evaluate(condition: IfConditionIR, scope: RuntimeScope) throws -> (passed: Bool, scope: RuntimeScope?) {
        switch condition {
        case .expression(let expr):
            let value = try ExpressionEvaluator.evaluate(expr, scope: scope)
            return (value?.asBool ?? false, nil)
        case .optionalBinding(let name, _, let expr):
            guard let evaluated = try ExpressionEvaluator.evaluate(expr, scope: scope) else {
                return (false, nil)
            }
            if case .void = evaluated {
                return (false, nil)
            }
            let bindingScope = RuntimeFunctionScope(parent: scope)
            bindingScope.define(name, value: evaluated)
            return (true, bindingScope)
        }
    }

    private func assign(value: RuntimeValue, to target: ExprIR, scope: RuntimeScope) throws {
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
                        "Cannot assign to member '\(name)' on \(baseValue.valueType)"
                    )
                }
            }
        default:
            throw RuntimeError.unsupportedAssignment("Unsupported assignment target")
        }
    }

    private func evaluateGuardConditions(_ conditions: [IfConditionIR], scope: RuntimeScope) throws -> Bool {
        for condition in conditions {
            switch condition {
            case .expression(let expr):
                let value = try ExpressionEvaluator.evaluate(expr, scope: scope)?.asBool ?? false
                if !value {
                    return false
                }
            case .optionalBinding(let name, _, let expr):
                guard let evaluated = try ExpressionEvaluator.evaluate(expr, scope: scope),
                      !evaluated.isNil else {
                    return false
                }
                scope.define(name, value: evaluated)
            }
        }
        return true
    }
}
