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
        case .view(let definition):
            return .viewDefinition(definition)
        case .function(let function):
            return .function(function)
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
                throw RuntimeError.unknownIdentifier(name)
            }
            let baseValue = try evaluate(base, scope: scope)
            let description = "\(baseValue?.description ?? "nil").\(name)"
            return .string(description)
        case .call(let callee, let arguments):
            let evaluatedArguments = try arguments.map { argument in
                let value = try evaluate(argument.value, scope: scope) ?? .void
                return RuntimeArgument(label: argument.label, value: value)
            }

            if case .identifier(let identifier) = callee {
                if let conversion = try evaluateTypeInitializer(name: identifier, arguments: evaluatedArguments) {
                    return conversion
                }

                if scope.builder(named: identifier) != nil || scope.viewDefinition(named: identifier) != nil {
                    return .view(RuntimeView(typeName: identifier, arguments: evaluatedArguments, scope: scope))
                }
            }

            guard let calleeValue = try evaluate(callee, scope: scope),
                  case .function(let function) = calleeValue else {
                throw RuntimeError.unsupportedExpression("Call target is not a function")
            }
            return try function.invoke(arguments: evaluatedArguments, scope: scope)
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
                    throw RuntimeError.unsupportedExpression("Unary + is not supported for \(operand.runtimeTypeDescription)")
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
                    throw RuntimeError.unsupportedExpression("Unary - is not supported for \(operand.runtimeTypeDescription)")
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
                    "Binary operator \(op.rawValue) is not supported between \(lhs.runtimeTypeDescription) and \(rhs.runtimeTypeDescription)"
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

    private static func evaluateTypeInitializer(
        name: String,
        arguments: [RuntimeArgument]
    ) throws -> RuntimeValue? {
        guard let numericType = NumericTypeInitializer(rawValue: name) else {
            return nil
        }

        guard arguments.count == 1,
              let value = arguments.first?.value else {
            throw RuntimeError.unsupportedExpression("\(name) initializer expects exactly one argument")
        }

        switch numericType {
        case .int:
            guard let intValue = value.asInt ?? value.asDouble.map(Int.init) else {
                throw RuntimeError.unsupportedExpression("Cannot convert \(value.runtimeTypeDescription) to Int")
            }
            return .int(intValue)
        case .double, .float, .cgfloat:
            guard let doubleValue = value.asDouble else {
                throw RuntimeError.unsupportedExpression("Cannot convert \(value.runtimeTypeDescription) to \(name)")
            }
            return .double(doubleValue)
        }
    }

    private enum NumericTypeInitializer: String {
        case int = "Int"
        case double = "Double"
        case float = "Float"
        case cgfloat = "CGFloat"
    }
}
