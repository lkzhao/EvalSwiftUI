import SwiftSyntax

public final class ExpressionResolver {
    private let defaultContext: (any SwiftUIEvaluatorContext)?

    public init(context: (any SwiftUIEvaluatorContext)? = nil) {
        self.defaultContext = context
    }

    func resolveExpression(
        _ expression: ExprSyntax,
        scope: ExpressionScope = [:],
        context externalContext: (any SwiftUIEvaluatorContext)? = nil
    ) throws -> SwiftValue {
        let context = externalContext ?? defaultContext

        if let parenthesized = expression.as(TupleExprSyntax.self),
           parenthesized.elements.count == 1,
           let element = parenthesized.elements.first,
           element.label == nil {
            return try resolveExpression(
                ExprSyntax(element.expression),
                scope: scope,
                context: context
            )
        }

        if let stringLiteral = expression.as(StringLiteralExprSyntax.self) {
            return .string(try stringLiteralValue(stringLiteral, scope: scope, context: context))
        }

        if let ternaryExpr = expression.as(TernaryExprSyntax.self) {
            let conditionValue = try resolveExpression(
                ExprSyntax(ternaryExpr.condition),
                scope: scope,
                context: context
            )
            let isTrue = try boolValue(from: conditionValue)
            if isTrue {
                return try resolveExpression(
                    ExprSyntax(ternaryExpr.thenExpression),
                    scope: scope,
                    context: context
                )
            }
            return try resolveExpression(
                ExprSyntax(ternaryExpr.elseExpression),
                scope: scope,
                context: context
            )
        }

        if let integerLiteral = expression.as(IntegerLiteralExprSyntax.self) {
            guard let value = Double(integerLiteral.literal.text) else {
                throw SwiftUIEvaluatorError.invalidArguments("Unable to parse integer literal \(integerLiteral.literal.text).")
            }
            return .number(value)
        }

        if let floatLiteral = expression.as(FloatLiteralExprSyntax.self) {
            guard let value = Double(floatLiteral.literal.text) else {
                throw SwiftUIEvaluatorError.invalidArguments("Unable to parse float literal \(floatLiteral.literal.text).")
            }
            return .number(value)
        }

        if let booleanLiteral = expression.as(BooleanLiteralExprSyntax.self) {
            return .bool(booleanLiteral.literal.text == "true")
        }

        if expression.is(NilLiteralExprSyntax.self) {
            return .optional(nil)
        }

        if let arrayLiteral = expression.as(ArrayExprSyntax.self) {
            let elements = try arrayLiteral.elements.map { element in
                try resolveExpression(
                    ExprSyntax(element.expression),
                    scope: scope,
                    context: context
                )
            }
            return .array(elements)
        }

        if let dictionaryLiteral = expression.as(DictionaryExprSyntax.self) {
            return try dictionaryValue(from: dictionaryLiteral, scope: scope, context: context)
        }

        if let sequenceExpr = expression.as(SequenceExprSyntax.self) {
            if let rangeValue = try resolveRangeExpression(
                sequenceExpr,
                scope: scope,
                context: context
            ) {
                return .range(rangeValue)
            }

            if let resolved = try resolveOperatorSequence(
                sequenceExpr,
                scope: scope,
                context: context
            ) {
                return resolved
            }
        }

        if let prefixOperator = expression.as(PrefixOperatorExprSyntax.self) {
            return try resolvePrefixOperator(
                prefixOperator,
                scope: scope,
                context: context
            )
        }

        if let keyPathExpr = expression.as(KeyPathExprSyntax.self) {
            return .keyPath(try keyPathValue(from: keyPathExpr))
        }

        if let functionCall = expression.as(FunctionCallExprSyntax.self) {
            return try resolveFunctionCall(functionCall, scope: scope, context: context)
        }

        if let subscriptExpr = expression.as(SubscriptCallExprSyntax.self) {
            return try resolveSubscriptExpression(
                subscriptExpr,
                scope: scope,
                context: context
            )
        }

        if let memberAccess = expression.as(MemberAccessExprSyntax.self) {
            return .memberAccess(try memberAccessPath(memberAccess))
        }

        if let reference = expression.as(DeclReferenceExprSyntax.self) {
            let identifier = reference.baseName.text
            if let scopedValue = scope[identifier] {
                return scopedValue
            }
            if identifier.hasPrefix("$"),
               let bindingTarget = scope[String(identifier.dropFirst())],
               case .state(let reference) = bindingTarget {
                return .binding(BindingValue(reference: reference))
            }
            if let externalValue = context?.value(for: identifier) {
                return externalValue
            }
            return .memberAccess([identifier])
        }

        throw SwiftUIEvaluatorError.unsupportedExpression(expression.description)
    }

    private func resolveOperatorSequence(
        _ sequence: SequenceExprSyntax,
        scope: ExpressionScope,
        context: (any SwiftUIEvaluatorContext)?
    ) throws -> SwiftValue? {
        let elements = Array(sequence.elements)
        guard elements.count >= 3, !elements.count.isMultiple(of: 2) else {
            return nil
        }

        if elements.count == 3,
           let unresolved = elements[1].as(UnresolvedTernaryExprSyntax.self) {
            let conditionValue = try resolveExpression(
                elements[0],
                scope: scope,
                context: context
            )
            let isTrue = try boolValue(from: conditionValue)
            if isTrue {
                return try resolveExpression(
                    ExprSyntax(unresolved.thenExpression),
                    scope: scope,
                    context: context
                )
            }
            return try resolveExpression(
                elements[2],
                scope: scope,
                context: context
            )
        }

        var operandExpressions: [ExprSyntax?] = []
        var operandValues: [SwiftValue?] = []
        var operators: [String] = []

        for (index, element) in elements.enumerated() {
            if index.isMultiple(of: 2) {
                operandExpressions.append(ExprSyntax(element))
                operandValues.append(nil)
            } else if let operatorExpr = element.as(BinaryOperatorExprSyntax.self) {
                operators.append(operatorExpr.operator.text)
            } else {
                return nil
            }
        }

        func resolveOperand(at index: Int) throws -> SwiftValue {
            if let cached = operandValues[index] {
                return cached
            }
            guard let expression = operandExpressions[index] else {
                throw SwiftUIEvaluatorError.unsupportedExpression("Operand resolution failed.")
            }
            let value = try resolveExpression(
                expression,
                scope: scope,
                context: context
            )
            operandValues[index] = value
            return value
        }

        enum Associativity {
            case left
            case right
        }

        let precedenceGroups: [(symbols: Set<String>, associativity: Associativity)] = [
            (symbols: Set(["*", "/", "%"]), associativity: .left),
            (symbols: Set(["+", "-"]), associativity: .left),
            (symbols: Set(["??"]), associativity: .right),
            (symbols: Set(["<", "<=", ">", ">=", "==", "!="]), associativity: .left),
            (symbols: Set(["&&"]), associativity: .left),
            (symbols: Set(["||"]), associativity: .left),
        ]

        for group in precedenceGroups {
            switch group.associativity {
            case .left:
                var index = 0
                while index < operators.count {
                    let symbol = operators[index]
                    if group.symbols.contains(symbol) {
                        let result = try applyBinaryOperator(
                            symbol,
                            lhs: { try resolveOperand(at: index) },
                            rhs: { try resolveOperand(at: index + 1) }
                        )
                        operandValues[index] = result
                        operandExpressions[index] = nil
                        operandExpressions.remove(at: index + 1)
                        operandValues.remove(at: index + 1)
                        operators.remove(at: index)
                    } else {
                        index += 1
                    }
                }
            case .right:
                var index = operators.count - 1
                while index >= 0 {
                    let symbol = operators[index]
                    if group.symbols.contains(symbol) {
                        let result = try applyBinaryOperator(
                            symbol,
                            lhs: { try resolveOperand(at: index) },
                            rhs: { try resolveOperand(at: index + 1) }
                        )
                        operandValues[index] = result
                        operandExpressions[index] = nil
                        operandExpressions.remove(at: index + 1)
                        operandValues.remove(at: index + 1)
                        operators.remove(at: index)
                    }
                    index -= 1
                }
            }
        }

        guard operators.isEmpty,
              operandExpressions.count == 1,
              operandValues.count == 1 else {
            return nil
        }

        if let cached = operandValues[0] {
            return cached
        }

        guard let expression = operandExpressions[0] else {
            return nil
        }

        return try resolveExpression(
            expression,
            scope: scope,
            context: context
        )
    }

    private func resolveSubscriptExpression(
        _ expression: SubscriptCallExprSyntax,
        scope: ExpressionScope,
        context: (any SwiftUIEvaluatorContext)?
    ) throws -> SwiftValue {
        let baseValue = try resolveExpression(
            expression.calledExpression,
            scope: scope,
            context: context
        )

        guard expression.arguments.count == 1,
              let argument = expression.arguments.first else {
            throw SwiftUIEvaluatorError.invalidArguments("Subscripts with multiple arguments are not supported.")
        }

        let indexValue = try resolveExpression(
            ExprSyntax(argument.expression),
            scope: scope,
            context: context
        )

        return try evaluateSubscript(base: baseValue, index: indexValue)
    }

    private func evaluateSubscript(base: SwiftValue, index: SwiftValue) throws -> SwiftValue {
        switch base.resolvingStateReference() {
        case .array(let elements):
            let position = try integerValue(from: index)
            guard elements.indices.contains(position) else {
                throw SwiftUIEvaluatorError.invalidArguments(
                    "Array subscript index \(position) is out of bounds."
                )
            }
            return elements[position]
        case .dictionary(let dictionary):
            let key = try dictionaryKey(from: index)
            if let value = dictionary[key] {
                return .optional(value)
            }
            return .optional(nil)
        case .optional(let wrapped):
            guard let unwrapped = wrapped?.unwrappedOptional() else {
                throw SwiftUIEvaluatorError.invalidArguments("Cannot subscript a nil value.")
            }
            return try evaluateSubscript(base: unwrapped, index: index)
        default:
            throw SwiftUIEvaluatorError.invalidArguments("Subscripts are only supported on arrays and dictionaries.")
        }
    }

    private func resolvePrefixOperator(
        _ expression: PrefixOperatorExprSyntax,
        scope: ExpressionScope,
        context: (any SwiftUIEvaluatorContext)?
    ) throws -> SwiftValue {
        let operatorToken = expression.`operator`

        let operand = try resolveExpression(
            ExprSyntax(expression.expression),
            scope: scope,
            context: context
        )

        switch operatorToken.text {
        case "!":
            let value = try boolValue(from: operand)
            return .bool(!value)
        case "-":
            let value = try numberValue(from: operand)
            return .number(-value)
        case "+":
            let value = try numberValue(from: operand)
            return .number(value)
        case "$":
            guard case .state(let reference) = operand else {
                throw SwiftUIEvaluatorError.invalidArguments("$ requires an @State-backed identifier.")
            }
            return .binding(BindingValue(reference: reference))
        default:
            throw SwiftUIEvaluatorError.unsupportedExpression(expression.description)
        }
    }

    private func resolveRangeExpression(
        _ sequence: SequenceExprSyntax,
        scope: ExpressionScope,
        context: (any SwiftUIEvaluatorContext)?
    ) throws -> RangeValue? {
        let elements = Array(sequence.elements)
        guard elements.count == 3 else {
            return nil
        }

        guard let operatorExpr = elements[1].as(BinaryOperatorExprSyntax.self) else {
            return nil
        }

        let style: RangeValue.Style
        switch operatorExpr.operator.text {
        case "..<":
            style = .halfOpen
        case "...":
            style = .closed
        default:
            return nil
        }

        let lowerValue = try resolveExpression(
            elements[0],
            scope: scope,
            context: context
        )
        let upperValue = try resolveExpression(
            elements[2],
            scope: scope,
            context: context
        )

        let lowerBound = try integerValue(from: lowerValue)
        let upperBound = try integerValue(from: upperValue)

        guard lowerBound <= upperBound else {
            throw SwiftUIEvaluatorError.invalidArguments("Range lower bound must be less than or equal to the upper bound.")
        }

        return RangeValue(lowerBound: lowerBound, upperBound: upperBound, style: style)
    }

    private func integerValue(from value: SwiftValue) throws -> Int {
        let resolved = value.resolvingStateReference()
        switch resolved {
        case .number(let number):
            guard number.truncatingRemainder(dividingBy: 1) == 0 else {
                throw SwiftUIEvaluatorError.invalidArguments("Integer expressions must resolve to whole numbers.")
            }
            return Int(number)
        case .optional(let wrapped):
            guard let unwrapped = wrapped?.unwrappedOptional() else {
                throw SwiftUIEvaluatorError.invalidArguments("Integer expressions cannot resolve to nil.")
            }
            return try integerValue(from: unwrapped)
        default:
            throw SwiftUIEvaluatorError.invalidArguments("Integer expressions must resolve to numeric values.")
        }
    }

    private func numberValue(from value: SwiftValue) throws -> Double {
        let resolved = value.resolvingStateReference()
        switch resolved {
        case .number(let number):
            return number
        case .optional(let wrapped):
            guard let unwrapped = wrapped?.unwrappedOptional() else {
                throw SwiftUIEvaluatorError.invalidArguments("Expected numeric value, received nil.")
            }
            return try numberValue(from: unwrapped)
        default:
            throw SwiftUIEvaluatorError.invalidArguments("Expected numeric value, received \(value.typeDescription).")
        }
    }

    private func boolValue(from value: SwiftValue) throws -> Bool {
        let resolved = value.resolvingStateReference()
        switch resolved {
        case .bool(let flag):
            return flag
        case .optional(let wrapped):
            guard let unwrapped = wrapped?.unwrappedOptional() else {
                throw SwiftUIEvaluatorError.invalidArguments("Expected boolean value, received nil.")
            }
            return try boolValue(from: unwrapped)
        default:
            throw SwiftUIEvaluatorError.invalidArguments("Expected boolean value, received \(value.typeDescription).")
        }
    }

    private func memberAccessPath(_ memberAccess: MemberAccessExprSyntax) throws -> [String] {
        var components: [String] = [memberAccess.declName.baseName.text]
        var currentBase = memberAccess.base

        while let baseExpr = currentBase {
            if let nestedMember = baseExpr.as(MemberAccessExprSyntax.self) {
                components.insert(nestedMember.declName.baseName.text, at: 0)
                currentBase = nestedMember.base
            } else if let reference = baseExpr.as(DeclReferenceExprSyntax.self) {
                components.insert(reference.baseName.text, at: 0)
                break
            } else {
                throw SwiftUIEvaluatorError.unsupportedExpression(baseExpr.description)
            }
        }

        return components
    }

    private func keyPathValue(from keyPath: KeyPathExprSyntax) throws -> KeyPathValue {
        let components = try keyPath.components.map { component -> String in
            guard let property = component.component.as(KeyPathPropertyComponentSyntax.self) else {
                throw SwiftUIEvaluatorError.invalidArguments("Only property key paths are supported in id arguments.")
            }
            return property.declName.baseName.text
        }
        return KeyPathValue(components: components)
    }

    private func dictionaryValue(
        from dictionary: DictionaryExprSyntax,
        scope: ExpressionScope,
        context: (any SwiftUIEvaluatorContext)?
    ) throws -> SwiftValue {
        switch dictionary.content {
        case .colon:
            return .dictionary([:])
        case .elements(let elements):
            var storage: [String: SwiftValue] = [:]
            for element in elements {
                let resolvedKey = try resolveExpression(
                    ExprSyntax(element.key),
                    scope: scope,
                    context: context
                )
                let key = try stringValue(from: resolvedKey)
                let resolvedValue = try resolveExpression(
                    ExprSyntax(element.value),
                    scope: scope,
                    context: context
                )
                storage[key] = resolvedValue
            }
            return .dictionary(storage)
        }
    }

    private func dictionaryKey(from value: SwiftValue) throws -> String {
        switch value.resolvingStateReference() {
        case .string(let string):
            return string
        case .optional(let wrapped):
            guard let unwrapped = wrapped?.unwrappedOptional() else {
                throw SwiftUIEvaluatorError.invalidArguments("Dictionary subscripts cannot use nil keys.")
            }
            return try dictionaryKey(from: unwrapped)
        default:
            throw SwiftUIEvaluatorError.invalidArguments("Dictionary subscripts require string keys.")
        }
    }

    private func containsValue(
        base: SwiftValue,
        element: SwiftValue
    ) throws -> Bool {
        let resolvedBase = base.resolvingStateReference()
        switch resolvedBase {
        case .array(let elements):
            return elements.contains { candidate in
                candidate.equals(element)
            }
        case .range(let rangeValue):
            let value = try integerValue(from: element)
            return rangeValue.contains(value)
        case .optional(let wrapped):
            guard let unwrapped = wrapped?.unwrappedOptional() else {
                return false
            }
            return try containsValue(base: unwrapped, element: element)
        default:
            throw SwiftUIEvaluatorError.invalidArguments("contains is only supported on arrays and ranges.")
        }
    }

    func evaluateCompoundAssignment(
        symbol: String,
        lhs: SwiftValue,
        rhs: SwiftValue
    ) throws -> SwiftValue {
        guard symbol.hasSuffix("=") else {
            throw SwiftUIEvaluatorError.invalidArguments("Unsupported compound assignment operator \(symbol).")
        }
        let binarySymbol = String(symbol.dropLast())
        return try applyBinaryOperator(
            binarySymbol,
            lhs: { lhs },
            rhs: { rhs }
        )
    }

    private func isStringLike(_ value: SwiftValue) -> Bool {
        guard let unwrapped = value.unwrappedOptional() else {
            return false
        }

        if case .string = unwrapped {
            return true
        }

        return false
    }

    private func applyBinaryOperator(
        _ symbol: String,
        lhs: () throws -> SwiftValue,
        rhs: () throws -> SwiftValue
    ) throws -> SwiftValue {
        switch symbol {
        case "+":
            let left = try lhs()
            let right = try rhs()
            if isStringLike(left) || isStringLike(right) {
                return .string(
                    try stringValue(from: left) + stringValue(from: right)
                )
            }
            return .number(try numberValue(from: left) + numberValue(from: right))
        case "-":
            return .number(try numberValue(from: lhs()) - numberValue(from: rhs()))
        case "*":
            return .number(try numberValue(from: lhs()) * numberValue(from: rhs()))
        case "/":
            return .number(try numberValue(from: lhs()) / numberValue(from: rhs()))
        case "%":
            let left = try numberValue(from: lhs())
            let right = try numberValue(from: rhs())
            return .number(left.truncatingRemainder(dividingBy: right))
        case "<":
            return .bool(try numberValue(from: lhs()) < numberValue(from: rhs()))
        case "<=":
            return .bool(try numberValue(from: lhs()) <= numberValue(from: rhs()))
        case ">":
            return .bool(try numberValue(from: lhs()) > numberValue(from: rhs()))
        case ">=":
            return .bool(try numberValue(from: lhs()) >= numberValue(from: rhs()))
        case "==":
            let left = try lhs()
            let right = try rhs()
            return .bool(left.equals(right))
        case "!=":
            let left = try lhs()
            let right = try rhs()
            return .bool(!left.equals(right))
        case "&&":
            let left = try boolValue(from: lhs())
            if !left {
                return .bool(false)
            }
            return .bool(try boolValue(from: rhs()))
        case "||":
            let left = try boolValue(from: lhs())
            if left {
                return .bool(true)
            }
            return .bool(try boolValue(from: rhs()))
        case "??":
            let left = try lhs()
            if let unwrapped = left.unwrappedOptional() {
                return unwrapped
            }
            return try rhs()
        default:
            throw SwiftUIEvaluatorError.unsupportedExpression(symbol)
        }
    }

    private func stringLiteralValue(
        _ literal: StringLiteralExprSyntax,
        scope: ExpressionScope,
        context: (any SwiftUIEvaluatorContext)?
    ) throws -> String {
        var result = ""

        for segment in literal.segments {
            if let stringSegment = segment.as(StringSegmentSyntax.self) {
                result.append(stringSegment.content.text)
            } else if let interpolation = segment.as(ExpressionSegmentSyntax.self) {
                guard interpolation.expressions.count == 1,
                      let element = interpolation.expressions.first else {
                    throw SwiftUIEvaluatorError.invalidArguments("Only simple string interpolation expressions are supported.")
                }
                let value = try resolveExpression(
                    ExprSyntax(element.expression),
                    scope: scope,
                    context: context
                )
                result.append(try stringValue(from: value))
            } else {
                throw SwiftUIEvaluatorError.invalidArguments("String interpolation is not supported.")
            }
        }

        return result
    }

    private func resolveFunctionCall(
        _ call: FunctionCallExprSyntax,
        scope: ExpressionScope,
        context: (any SwiftUIEvaluatorContext)?
    ) throws -> SwiftValue {
        let name: [String]
        if let memberAccess = call.calledExpression.as(MemberAccessExprSyntax.self) {
            if let value = try resolveMemberFunctionCall(
                memberAccess,
                call: call,
                scope: scope,
                context: context
            ) {
                return value
            }
            name = try memberAccessPath(memberAccess)
        } else if let reference = call.calledExpression.as(DeclReferenceExprSyntax.self) {
            name = [reference.baseName.text]
        } else {
            throw SwiftUIEvaluatorError.unsupportedExpression(call.description)
        }

        let arguments = try resolveCallArguments(call.arguments, scope: scope, context: context)
        return .functionCall(FunctionCallValue(name: name, arguments: arguments))
    }

    private func resolveMemberFunctionCall(
        _ memberAccess: MemberAccessExprSyntax,
        call: FunctionCallExprSyntax,
        scope: ExpressionScope,
        context: (any SwiftUIEvaluatorContext)?
    ) throws -> SwiftValue? {
        guard let baseExpression = memberAccess.base else {
            return nil
        }

        let baseValue = try resolveExpression(
            ExprSyntax(baseExpression),
            scope: scope,
            context: context
        )

        switch memberAccess.declName.baseName.text {
        case "contains":
            return try resolveContainsCall(
                baseValue: baseValue,
                arguments: call.arguments,
                scope: scope,
                context: context
            )
        default:
            return nil
        }
    }

    private func resolveContainsCall(
        baseValue: SwiftValue,
        arguments: LabeledExprListSyntax,
        scope: ExpressionScope,
        context: (any SwiftUIEvaluatorContext)?
    ) throws -> SwiftValue? {
        guard let argument = arguments.first, arguments.count == 1 else {
            throw SwiftUIEvaluatorError.invalidArguments("contains expects exactly one argument.")
        }

        let element = try resolveExpression(
            ExprSyntax(argument.expression),
            scope: scope,
            context: context
        )

        return .bool(try containsValue(base: baseValue, element: element))
    }

    private func resolveCallArguments(
        _ arguments: LabeledExprListSyntax,
        scope: ExpressionScope,
        context: (any SwiftUIEvaluatorContext)?
    ) throws -> [ResolvedArgument] {
        try arguments.map { element in
            let value = try resolveExpression(
                ExprSyntax(element.expression),
                scope: scope,
                context: context
            )
            return ResolvedArgument(label: element.label?.text, value: value)
        }
    }

    private func stringValue(from value: SwiftValue) throws -> String {
        let resolved = value.resolvingStateReference()
        switch resolved {
        case .string(let string):
            return string
        case .number(let number):
            return number.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(number))
                : String(number)
        case .bool(let flag):
            return String(flag)
        case .optional(let wrapped):
            guard let unwrapped = wrapped?.unwrappedOptional() else {
                return "nil"
            }
            return try stringValue(from: unwrapped)
        default:
            throw SwiftUIEvaluatorError.invalidArguments(
                "String interpolation expects string, numeric, boolean, or optional values, received \(value.typeDescription)."
            )
        }
    }
}
