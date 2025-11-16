import Foundation
import SwiftUI
import EvalSwiftIR

struct ExpressionEvaluator {
    static func evaluate(
        _ expression: ExprIR?,
        scope: RuntimeScope,
        expectedType: String? = nil
    ) throws -> RuntimeValue? {
        guard let expression else { return nil }
        switch expression {
        case .identifier(let name):
            if Self.isBindingIdentifier(name) {
                let identifier = String(name.dropFirst())
                return try Self.makeBinding(named: identifier, scope: scope)
            }
            return try scope.get(name)
        case .int(let value):
            return .int(value)
        case .double(let value):
            return .double(value)
        case .bool(let value):
            return .bool(value)
        case .string(let string):
            return .string(string)
        case .nilLiteral:
            return .void
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
            guard let lhs = try evaluate(lhsExpr, scope: scope) else {
                throw RuntimeError.unsupportedExpression("Binary operator \(op.rawValue) requires valid operands")
            }
            if op.isLogical {
                return try evaluateLogicalBinary(op: op, lhs: lhs, rhsExpr: rhsExpr, scope: scope)
            }
            guard let rhs = try evaluate(rhsExpr, scope: scope) else {
                throw RuntimeError.unsupportedExpression("Binary operator \(op.rawValue) requires valid operands")
            }
            return try evaluateBinary(op: op, lhs: lhs, rhs: rhs)
        case .ternary(let condition, let trueValue, let falseValue):
            let predicate = try evaluate(condition, scope: scope)?.asBool ?? false
            if predicate {
                return try evaluate(trueValue, scope: scope, expectedType: expectedType)
            } else {
                return try evaluate(falseValue, scope: scope, expectedType: expectedType)
            }
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

                if let instance = baseValue.asInstance {
                    do {
                        return try instance.get(name)
                    } catch RuntimeError.unknownIdentifier {
                        // fall through to method lookup
                    } catch {
                        throw error
                    }
                }
                if case .type(let type) = baseValue {
                    do {
                        return try type.get(name)
                    } catch RuntimeError.unknownIdentifier {
                        // fall through
                    } catch {
                        throw error
                    }
                }

                if let builder = scope.module?.methodBuilder(named: name) {
                    return try applyMethodBuilder(
                        builder: builder,
                        baseValue: baseValue,
                        setter: nil,
                        arguments: [],
                        scope: scope
                    )
                }

                throw RuntimeError.unsupportedExpression(
                    "Cannot access member '\(name)' on \(baseValue.valueType)"
                )
            } else {
                if let implicit = try? scope.getImplicitMember(name, expectedType: expectedType) {
                    return implicit
                }
                return try scope.get(name)
            }
        case .call(let callee, let arguments):
            if let staticResult = try evaluateStaticCallIfNeeded(
                callee: callee,
                arguments: arguments,
                scope: scope,
                expectedType: expectedType
            ) {
                return staticResult
            }
            if case .member(let baseExpr, let name) = callee {
                guard let baseExpr,
                      let baseValue = try evaluate(baseExpr, scope: scope) else {
                    throw RuntimeError.invalidArgument("Method '\(name)' requires a receiver.")
                }
                let setter = makeSetter(from: baseExpr, scope: scope)

                if let builder = scope.module?.methodBuilder(named: name) {
                    return try applyMethodBuilder(
                        builder: builder,
                        baseValue: baseValue,
                        setter: setter,
                        arguments: arguments,
                        scope: scope
                    )
                }

                if let shapeResult = try evaluateShapeFunction(
                    name: name,
                    baseValue: baseValue,
                    arguments: arguments,
                    scope: scope
                ) {
                    return shapeResult
                }
            }

            if let calleeValue = try evaluate(callee, scope: scope) {
                if case .function(let function) = calleeValue {
                    let evaluatedArguments = try ArgumentEvaluator.evaluate(parameters: function.parameters, arguments: arguments, scope: scope)
                    return try function.invoke(arguments: evaluatedArguments)
                } else if case .type(let type) = calleeValue {
                    return try makeValue(type: type, arguments: arguments, scope: scope)
                }
            }

            throw RuntimeError.unsupportedExpression("No matching call for \(callee) arguments: \(arguments)")
        case .unknown(let raw):
            throw RuntimeError.unsupportedExpression(raw)
        case .`subscript`(let baseExpr, let arguments):
            guard let baseValue = try evaluate(baseExpr, scope: scope) else {
                throw RuntimeError.unsupportedExpression("Subscript requires a base value.")
            }
            let resolvedArguments = try arguments.map { argument -> RuntimeValue in
                guard let value = try evaluate(argument.value, scope: scope) else {
                    throw RuntimeError.unsupportedExpression("Subscript argument requires a value.")
                }
                return value
            }
            return try evaluateSubscript(base: baseValue, arguments: resolvedArguments)
        }
    }

    private static func makeValue(type: RuntimeType, arguments: [FunctionCallArgumentIR], scope: RuntimeScope) throws -> RuntimeValue? {
        let definitions = type.definitions
        var lastError: Error?
        let isDebugLoggingEnabled = ProcessInfo.processInfo.environment["RUNTIME_DEBUG"] != nil
        for definition in definitions {
            do {
                let evaluatedArguments = try ArgumentEvaluator.evaluate(
                    parameters: definition.parameters,
                    arguments: arguments,
                    scope: scope
                )
                let result = try definition.build(evaluatedArguments, scope)
                return result
            } catch {
                if isDebugLoggingEnabled {
                    print("Failed to match initializer on type \(type.name) with arguments count \(arguments.count): \(error)")
                }
                lastError = error
            }
        }
        throw lastError ?? RuntimeError.invalidArgument("No matching initializer for type '\(type.name)'.")
    }

    private static func makeBinding(named name: String, scope: RuntimeScope) throws -> RuntimeValue {
        let binding = RuntimeBinding(
            getter: {
                try scope.get(name)
            },
            setter: { newValue in
                try scope.set(name, value: newValue)
            }
        )
        return .binding(binding)
    }

    private static func isBindingIdentifier(_ name: String) -> Bool {
        guard name.hasPrefix("$"), name.count > 1 else {
            return false
        }
        let nextCharacter = name[name.index(after: name.startIndex)]
        return nextCharacter.isLetter || nextCharacter == "_"
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
        case .not:
            guard let boolValue = operand.asBool else {
                throw RuntimeError.unsupportedExpression("Unary ! is not supported for \(operand.valueType)")
            }
            return .bool(!boolValue)
        }
    }

    private static func identifierName(from expression: ExprIR?) -> String? {
        guard let expression else { return nil }
        if case .identifier(let name) = expression {
            return name
        }
        return nil
    }

    private static func evaluateSubscript(base: RuntimeValue, arguments: [RuntimeValue]) throws -> RuntimeValue {
        switch base {
        case .array(let values):
            guard arguments.count == 1 else {
                throw RuntimeError.invalidArgument("Array subscript expects exactly one argument.")
            }
            guard let index = arguments.first?.asInt else {
                throw RuntimeError.invalidArgument("Array subscript requires an integer index.")
            }
            guard values.indices.contains(index) else {
                throw RuntimeError.invalidArgument("Array index \(index) out of range.")
            }
            return values[index]
        case .dictionary(let dictionary):
            guard arguments.count == 1 else {
                throw RuntimeError.invalidArgument("Dictionary subscript expects exactly one argument.")
            }
            guard let key = arguments.first?.asAnyHashable else {
                throw RuntimeError.invalidArgument("Dictionary subscript requires a Hashable key.")
            }
            return dictionary[key] ?? .void
        default:
            throw RuntimeError.invalidArgument("Subscript is not supported for \(base.valueType).")
        }
    }

    private static func evaluateBinary(
        op: BinaryOperatorIR,
        lhs: RuntimeValue,
        rhs: RuntimeValue
    ) throws -> RuntimeValue {

        if op.isComparison {
            return try evaluateComparison(op: op, lhs: lhs, rhs: rhs)
        }

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
        default:
            throw RuntimeError.unsupportedExpression("Operator \(op.rawValue) is not supported for integers.")
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
        default:
            throw RuntimeError.unsupportedExpression("Operator \(op.rawValue) is not supported for floating point values.")
        }
        return .double(result)
    }

    private static func evaluateComparison(
        op: BinaryOperatorIR,
        lhs: RuntimeValue,
        rhs: RuntimeValue
    ) throws -> RuntimeValue {
        if let leftNumber = lhs.asDouble, let rightNumber = rhs.asDouble {
            let result: Bool
            switch op {
            case .equal:
                result = leftNumber == rightNumber
            case .notEqual:
                result = leftNumber != rightNumber
            case .lessThan:
                result = leftNumber < rightNumber
            case .lessThanOrEqual:
                result = leftNumber <= rightNumber
            case .greaterThan:
                result = leftNumber > rightNumber
            case .greaterThanOrEqual:
                result = leftNumber >= rightNumber
            default:
                result = false
            }
            return .bool(result)
        }

        if case .bool(let leftBool) = lhs,
           case .bool(let rightBool) = rhs,
           op == .equal || op == .notEqual {
            let result = op == .equal ? (leftBool == rightBool) : (leftBool != rightBool)
            return .bool(result)
        }

        if case .string(let leftString) = lhs,
           case .string(let rightString) = rhs,
           op == .equal || op == .notEqual {
            let result = op == .equal ? (leftString == rightString) : (leftString != rightString)
            return .bool(result)
        }

        if case .enumCase(let leftCase) = lhs,
           case .enumCase(let rightCase) = rhs,
           op == .equal || op == .notEqual {
            let result = op == .equal ? (leftCase == rightCase) : (leftCase != rightCase)
            return .bool(result)
        }

        throw RuntimeError.unsupportedExpression("Comparison operator \(op.rawValue) is not supported between \(lhs.valueType) and \(rhs.valueType)")
    }

    private static func evaluateLogicalBinary(
        op: BinaryOperatorIR,
        lhs: RuntimeValue,
        rhsExpr: ExprIR,
        scope: RuntimeScope
    ) throws -> RuntimeValue {
        let left = lhs.asBool ?? false
        switch op {
        case .logicalAnd:
            if !left {
                return .bool(false)
            }
            let right = try ExpressionEvaluator.evaluate(rhsExpr, scope: scope)?.asBool ?? false
            return .bool(right)
        case .logicalOr:
            if left {
                return .bool(true)
            }
            let right = try ExpressionEvaluator.evaluate(rhsExpr, scope: scope)?.asBool ?? false
            return .bool(right)
        default:
            throw RuntimeError.unsupportedExpression("Logical operator \(op.rawValue) is not supported.")
        }
    }

    private static func evaluateStaticCallIfNeeded(
        callee: ExprIR,
        arguments: [FunctionCallArgumentIR],
        scope: RuntimeScope,
        expectedType: String?
    ) throws -> RuntimeValue? {
        guard case .member(let baseExpr, let memberName) = callee else {
            return nil
        }

        let resolvedTypeName: String?
        if let baseExpr,
           case .identifier(let explicitType) = baseExpr {
            resolvedTypeName = explicitType
        } else {
            resolvedTypeName = expectedType
        }

        guard let typeName = resolvedTypeName else {
            return nil
        }

        switch (typeName, memberName) {
        case ("Font", "system"):
            guard let sizeValue = try value(labeled: "size", in: arguments, scope: scope)?.asDouble else {
                throw RuntimeError.invalidArgument("Font.system(size:weight:) requires a size argument.")
            }
            let weight = try value(labeled: "weight", in: arguments, scope: scope)?.asFontWeight ?? .regular
            let font = Font.system(size: CGFloat(sizeValue), weight: weight)
            return .swiftUI(.font(font))
        default:
            return nil
        }
    }

    private static func evaluateShapeFunction(
        name: String,
        baseValue: RuntimeValue,
        arguments: [FunctionCallArgumentIR],
        scope: RuntimeScope
    ) throws -> RuntimeValue? {
        guard let shape = baseValue.asShape else { return nil }
        switch name {
        case "fill":
            guard let firstArgument = arguments.first,
                  let styleValue = try evaluate(firstArgument.value, scope: scope),
                  let style = styleValue.asShapeStyle else {
                throw RuntimeError.invalidArgument("fill(_:) expects a ShapeStyle argument.")
            }
            return .swiftUI(.view(AnyView(shape.fill(style))))
        case "stroke":
            guard let styleArgument = arguments.first,
                  let styleValue = try evaluate(styleArgument.value, scope: scope),
                  let style = styleValue.asShapeStyle else {
                throw RuntimeError.invalidArgument("stroke(_:) expects a ShapeStyle argument.")
            }
            let width = try resolveLineWidth(arguments: arguments, scope: scope)
            return .swiftUI(.view(AnyView(shape.stroke(style, lineWidth: width))))
        case "strokeBorder":
            guard let insettable = baseValue.asInsettableShape else {
                throw RuntimeError.invalidArgument("strokeBorder(_:) requires an InsettableShape receiver.")
            }
            guard let styleArgument = arguments.first,
                  let styleValue = try evaluate(styleArgument.value, scope: scope),
                  let style = styleValue.asShapeStyle else {
                throw RuntimeError.invalidArgument("strokeBorder(_:) expects a ShapeStyle argument.")
            }
            let width = try resolveLineWidth(arguments: arguments, scope: scope)
            let stroked = insettable.strokeBorder(style, lineWidth: width)
            return .swiftUI(.view(AnyView(stroked)))
        default:
            return nil
        }
    }

    private static func resolveLineWidth(
        arguments: [FunctionCallArgumentIR],
        scope: RuntimeScope,
        defaultWidth: CGFloat = 1
    ) throws -> CGFloat {
        if let labeled = arguments.first(where: { $0.label == "lineWidth" }),
           let value = try evaluate(labeled.value, scope: scope)?.asCGFloat {
            return value
        }
        if arguments.count > 1,
           let value = try evaluate(arguments[1].value, scope: scope)?.asCGFloat {
            return value
        }
        return defaultWidth
    }

    private static func value(
        labeled label: String,
        in arguments: [FunctionCallArgumentIR],
        scope: RuntimeScope
    ) throws -> RuntimeValue? {
        guard let argument = arguments.first(where: { $0.label == label }) else {
            return nil
        }
        return try evaluate(argument.value, scope: scope)
    }

    private static func applyMethodBuilder(
        builder: RuntimeMethodBuilder,
        baseValue: RuntimeValue,
        setter: ((RuntimeValue) throws -> Void)? = nil,
        arguments: [FunctionCallArgumentIR],
        scope: RuntimeScope
    ) throws -> RuntimeValue {
        var lastError: Error?
        for definition in builder.definitions {
            do {
                let evaluatedArguments = try ArgumentEvaluator.evaluate(
                    parameters: definition.parameters,
                    arguments: arguments,
                    scope: scope
                )
                if case .instance(let instance) = baseValue,
                   let viewDefinition = definition as? RuntimeViewMethodDefinition {
                    let modifiedInstance = RuntimeInstance(
                        methodDefinition: viewDefinition,
                        arguments: evaluatedArguments,
                        parent: instance
                    )
                    return .instance(modifiedInstance)
                }
                return try definition.apply(
                    to: baseValue,
                    setter: setter,
                    arguments: evaluatedArguments,
                    scope: scope
                )
            } catch {
                lastError = error
            }
        }
        throw lastError ?? RuntimeError.invalidArgument("No matching method '\(builder.name)'.")
    }

    private static func makeSetter(from baseExpr: ExprIR?, scope: RuntimeScope) -> ((RuntimeValue) throws -> Void)? {
        guard let identifier = identifierName(from: baseExpr) else {
            return nil
        }
        return { newValue in
            try scope.set(identifier, value: newValue)
        }
    }
}

private extension BinaryOperatorIR {
    var isComparison: Bool {
        switch self {
        case .equal, .notEqual, .lessThan, .lessThanOrEqual, .greaterThan, .greaterThanOrEqual:
            return true
        default:
            return false
        }
    }

    var isLogical: Bool {
        switch self {
        case .logicalAnd, .logicalOr:
            return true
        default:
            return false
        }
    }
}
