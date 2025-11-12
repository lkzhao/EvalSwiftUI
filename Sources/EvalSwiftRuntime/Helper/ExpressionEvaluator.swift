import Foundation
import EvalSwiftIR

struct ExpressionEvaluator {
    static func evaluate(_ expression: ExprIR?, scope: RuntimeScope) throws -> RuntimeValue? {
        guard let expression else { return nil }
        switch expression {
        case .identifier(let name):
            return try scope.get(name)
        case .literal(let raw):
            if let integer = Int(raw) {
                return .int(integer)
            }
            if let number = Double(raw) {
                return .double(number)
            }
            if raw == "true" { return .bool(true) }
            if raw == "false" { return .bool(false) }
            if raw.hasPrefix("[") && raw.hasSuffix("]") {
                let trimmed = raw.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
                let elements = trimmed.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
                let values = elements.map { RuntimeValue.string($0.trimmingCharacters(in: CharacterSet(charactersIn: "\""))) }
                return .array(values)
            }
            return .string(raw.trimmingCharacters(in: CharacterSet(charactersIn: "\"")))
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
            if case .identifier(let viewName) = callee {
                let evaluatedArguments = try arguments.map { argument in
                    let value = try evaluate(argument.value, scope: scope) ?? .void
                    return RuntimeArgument(label: argument.label, value: value)
                }

                if scope.builder(named: viewName) != nil || scope.viewDefinition(named: viewName) != nil {
                    return .view(RuntimeView(typeName: viewName, arguments: evaluatedArguments))
                }
            }

            guard let calleeValue = try evaluate(callee, scope: scope),
                  case .function(let function) = calleeValue else {
                throw RuntimeError.unsupportedExpression("Call target is not a function")
            }
            let resolvedArguments = try arguments.map { argument in
                let value = try evaluate(argument.value, scope: scope) ?? .void
                return RuntimeArgument(label: argument.label, value: value)
            }
            return try function.invoke(arguments: resolvedArguments, scope: scope)
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
        }
        return .double(result)
    }
}
