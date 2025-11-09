import SwiftSyntax

extension ExpressionResolver {
    func resolveOperatorSequence(
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
            (symbols: Set(["||"]), associativity: .left)
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

    func resolveSubscriptExpression(
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

    func resolvePrefixOperator(
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
            return operand
        default:
            throw SwiftUIEvaluatorError.unsupportedExpression(expression.description)
        }
    }

    func resolveRangeExpression(
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

    func integerValue(from value: SwiftValue) throws -> Int {
        try value.asInt()
    }

    func numberValue(from value: SwiftValue) throws -> Double {
        try value.asDouble()
    }

    func boolValue(from value: SwiftValue) throws -> Bool {
        try value.asBool()
    }

    func memberAccessPath(_ memberAccess: MemberAccessExprSyntax) throws -> [String] {
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

    func keyPathValue(from keyPath: KeyPathExprSyntax) throws -> KeyPathValue {
        let components = try keyPath.components.map { component -> String in
            guard let property = component.component.as(KeyPathPropertyComponentSyntax.self) else {
                throw SwiftUIEvaluatorError.invalidArguments("Only property key paths are supported in id arguments.")
            }
            return property.declName.baseName.text
        }
        return KeyPathValue(components: components)
    }

    func dictionaryValue(
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

    func resolveFunctionCall(
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

    func stringLiteralValue(
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

    func stringValue(from value: SwiftValue) throws -> String {
        switch value.payload {
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

    func applyBinaryOperator(
        _ symbol: String,
        lhs: () throws -> SwiftValue,
        rhs: () throws -> SwiftValue
    ) throws -> SwiftValue {
        switch symbol {
        case "+":
            let left = try lhs()
            let right = try rhs()
            let leftIsString = (try? left.asString()) != nil
            let rightIsString = (try? right.asString()) != nil
            if leftIsString || rightIsString {
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
}

extension ExpressionResolver {
    func evaluateSubscript(base: SwiftValue, index: SwiftValue) throws -> SwiftValue {
        switch base.payload {
        case .array(let elements):
            let position = try integerValue(from: index)
            guard elements.indices.contains(position) else {
                throw SwiftUIEvaluatorError.invalidArguments(
                    "Array subscript index \(position) is out of bounds."
                )
            }
            return elements[position]
        case .dictionary(let dictionary):
            let key = try index.asString()
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

    func resolveMemberFunctionCall(
        _ memberAccess: MemberAccessExprSyntax,
        call: FunctionCallExprSyntax,
        scope: ExpressionScope,
        context: (any SwiftUIEvaluatorContext)?
    ) throws -> SwiftValue? {
        let functionName = memberAccess.declName.baseName.text
        guard memberFunctionRegistry.handler(named: functionName) != nil else {
            return nil
        }

        guard let baseExpression = memberAccess.base else {
            return nil
        }

        let baseValue = try resolveExpression(
            ExprSyntax(baseExpression),
            scope: scope,
            context: context
        )

        let arguments = try resolveCallArguments(
            call.arguments,
            scope: scope,
            context: context
        )

        let handlerContext = ChainContext(contexts: [DictionaryContext(values: scope), context].compactMap { $0 })

        return try memberFunctionRegistry.call(
            name: functionName,
            baseValue: baseValue,
            arguments: arguments,
            context: handlerContext
        )
    }

    func resolveCallArguments(
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

}
