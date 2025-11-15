import Foundation
import EvalSwiftIR

struct ExpressionEvaluator {
    static func evaluate(_ expression: ExprIR?, scope: RuntimeScope) throws -> RuntimeValue? {
        guard let expression else { return nil }
        switch expression {
        case .identifier(let name):
            return try scope.get(name)
        case .int(let value):
            return .int(value)
        case .double(let value):
            return .double(value)
        case .bool(let value):
            return .bool(value)
        case .string(let string):
            return .string(string)
        case .array(let expressions):
            let values = try expressions.map { expr -> RuntimeValue in
                guard let value = try evaluate(expr, scope: scope) else { return .void }
                return value
            }
            return .array(values)
        case .keyPath(let keyPath):
            return .keyPath(keyPath)
        case .stringInterpolation(let segments):
            let resolved = try segments.map { segment -> String in
                switch segment {
                case .literal(let literal):
                    return literal
                case .expression(let expr):
                    guard let value = try evaluate(expr, scope: scope) else {
                        return ""
                    }
                    return value.asString ?? value.description
                }
            }.joined()
            return .string(resolved)
        case .definition(let definition):
            return .type(try RuntimeType(ir: definition, parent: scope))
        case .function(let function):
            return .function(try RuntimeFunction(ir: function, parent: scope))
        case .unary(let op, let operandExpr):
            guard let operand = try evaluate(operandExpr, scope: scope) else {
                throw RuntimeError.unsupportedExpression("Unary operator \(op.rawValue) requires a value")
            }
            return try evaluateUnary(op: op, operand: operand)
        case .binary(let op, let lhsExpr, let rhsExpr):
            guard let lhs = try evaluate(lhsExpr, scope: scope),
                  let rhs = try evaluate(rhsExpr, scope: scope) else {
                throw RuntimeError.unsupportedExpression("Binary operator \(op.rawValue) requires valid operands")
            }
            return try evaluateBinary(op: op, lhs: lhs, rhs: rhs)
        case .member(let base, let name):
            if case .identifier("self") = base {
                if let instance = scope.instance {
                    return try instance.get(name)
                }
                throw RuntimeError.unknownIdentifier("self.\(name)")
            } else if case .identifier("Self") = base {
                if let type = scope.type {
                    return try type.get(name)
                }
                throw RuntimeError.unknownIdentifier("Self.\(name)")
            } else if let base {
                guard let baseValue = try evaluate(base, scope: scope) else {
                    throw RuntimeError.unsupportedExpression("Member access for '\(name)' requires a value")
                }

                switch baseValue {
                case .instance(let instance):
                    return try instance.get(name)
                case .type(let type):
                    return try type.get(name)
                default:
                    throw RuntimeError.unsupportedExpression(
                        "Cannot access member '\(name)' on \(baseValue.valueType)"
                    )
                }
            } else {
                return try scope.get(name)
            }
        case .call(let callee, let arguments):
            if case .member(let baseExpr, let name) = callee,
               let modifierBuilder = scope.module?.modifierBuilder(named: name) {
                guard let baseValue = try evaluate(baseExpr, scope: scope) else {
                    throw RuntimeError.invalidArgument("\(name) modifier requires a SwiftUI view as the receiver.")
                }

                var resolvedDefinition: (RuntimeModifierDefinition, [RuntimeArgument])?
                for definition in modifierBuilder.definitions {
                    if let evaluatedArguments = try? ArgumentEvaluator.evaluate(
                        parameters: definition.parameters,
                        arguments: arguments,
                        scope: scope
                    ) {
                        resolvedDefinition = (definition, evaluatedArguments)
                        break
                    }
                }

                guard let (definition, evaluatedArguments) = resolvedDefinition else {
                    throw RuntimeError.invalidArgument("No matching signature for modifier '\(name)'.")
                }

                if case .instance(let instance) = baseValue {
                    let modifiedInstance = RuntimeInstance(
                        modifierDefinition: definition,
                        arguments: evaluatedArguments,
                        parent: instance
                    )
                    return .instance(modifiedInstance)
                }

                return try definition.apply(
                    to: baseValue,
                    arguments: evaluatedArguments,
                    scope: scope
                )
            }

            if case .identifier(let typeName) = callee,
                let type = try? scope.type(named: typeName) {
                let definitions = type.definitions
                for definition in definitions {
                    if let evaluatedArguments = try? ArgumentEvaluator.evaluate(parameters: definition.parameters, arguments: arguments, scope: scope), let result = try? definition.build(evaluatedArguments, scope) {
                        return result
                    }
                }
            }

            if let calleeValue = try evaluate(callee, scope: scope),
                      case .function(let function) = calleeValue {
                let evaluatedArguments = try ArgumentEvaluator.evaluate(parameters: function.parameters, arguments: arguments, scope: scope)
                return try function.invoke(arguments: evaluatedArguments)
            }

            throw RuntimeError.unsupportedExpression("No matching call for \(callee) arguments: \(arguments)")
        case .unknown(let raw):
            throw RuntimeError.unsupportedExpression(raw)
        }
    }

    private static func evaluateUnary(
        op: UnaryOperatorIR,
        operand: RuntimeValue
    ) throws -> RuntimeValue {
        switch op {
        case .plus:
            switch operand {
            case .int, .double:
                return operand
            default:
                guard let numeric = operand.asDouble else {
                    throw RuntimeError.unsupportedExpression("Unary + is not supported for \(operand.valueType)")
                }
                return .double(numeric)
            }
        case .minus:
            switch operand {
            case .int(let value):
                return .int(-value)
            case .double(let number):
                return .double(-number)
            default:
                guard let numeric = operand.asDouble else {
                    throw RuntimeError.unsupportedExpression("Unary - is not supported for \(operand.valueType)")
                }
                return .double(-numeric)
            }
        }
    }

    private static func evaluateBinary(
        op: BinaryOperatorIR,
        lhs: RuntimeValue,
        rhs: RuntimeValue
    ) throws -> RuntimeValue {
        if op == .rangeExclusive || op == .rangeInclusive {
            guard let left = lhs.asInt, let right = rhs.asInt else {
                throw RuntimeError.unsupportedExpression("Range operators require Int operands")
            }
            return try evaluateIntegerBinary(op: op, lhs: left, rhs: right)
        }

        switch (lhs, rhs) {
        case (.int(let left), .int(let right)):
            return try evaluateIntegerBinary(op: op, lhs: left, rhs: right)
        default:
            guard let left = lhs.asDouble,
                  let right = rhs.asDouble else {
                throw RuntimeError.unsupportedExpression(
                    "Binary operator \(op.rawValue) is not supported between \(lhs.valueType) and \(rhs.valueType)"
                )
            }
            return try evaluateFloatingBinary(op: op, lhs: left, rhs: right)
        }
    }

    private static func evaluateIntegerBinary(
        op: BinaryOperatorIR,
        lhs: Int,
        rhs: Int
    ) throws -> RuntimeValue {
        switch op {
        case .addition:
            return .int(lhs + rhs)
        case .subtraction:
            return .int(lhs - rhs)
        case .multiplication:
            return .int(lhs * rhs)
        case .division:
            guard rhs != 0 else {
                throw RuntimeError.unsupportedExpression("Division by zero")
            }
            return .int(lhs / rhs)
        case .remainder:
            guard rhs != 0 else {
                throw RuntimeError.unsupportedExpression("Modulo by zero")
            }
            return .int(lhs % rhs)
        case .rangeExclusive:
            if rhs <= lhs { return .array([]) }
            let values = Array(lhs..<rhs).map { RuntimeValue.int($0) }
            return .array(values)
        case .rangeInclusive:
            if rhs < lhs { return .array([]) }
            let values = Array(lhs...rhs).map { RuntimeValue.int($0) }
            return .array(values)
        }
    }

    private static func evaluateFloatingBinary(
        op: BinaryOperatorIR,
        lhs: Double,
        rhs: Double
    ) throws -> RuntimeValue {
        let result: Double
        switch op {
        case .addition:
            result = lhs + rhs
        case .subtraction:
            result = lhs - rhs
        case .multiplication:
            result = lhs * rhs
        case .division:
            guard rhs != 0 else {
                throw RuntimeError.unsupportedExpression("Division by zero")
            }
            result = lhs / rhs
        case .remainder:
            guard rhs != 0 else {
                throw RuntimeError.unsupportedExpression("Modulo by zero")
            }
            result = lhs.truncatingRemainder(dividingBy: rhs)
        case .rangeExclusive, .rangeInclusive:
            throw RuntimeError.unsupportedExpression("Range operators require integer operands")
        }
        return .double(result)
    }
}
