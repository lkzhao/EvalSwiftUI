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
            guard case .state(let reference) = operand else {
                throw SwiftUIEvaluatorError.invalidArguments("$ requires an @State-backed identifier.")
            }
            return .binding(BindingValue(reference: reference))
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

    func numberValue(from value: SwiftValue) throws -> Double {
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

    func boolValue(from value: SwiftValue) throws -> Bool {
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

    func applyBinaryOperator(
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
}

extension ExpressionResolver {
    func evaluateSubscript(base: SwiftValue, index: SwiftValue) throws -> SwiftValue {
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

    func dictionaryKey(from value: SwiftValue) throws -> String {
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

    func isStringLike(_ value: SwiftValue) -> Bool {
        guard let unwrapped = value.unwrappedOptional() else {
            return false
        }
        if case .string = unwrapped {
            return true
        }
        return false
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

        return try memberFunctionRegistry.call(
            name: functionName,
            baseValue: baseValue,
            arguments: arguments,
            resolver: self,
            scope: scope,
            context: context
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

    func containsValue(
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
}

extension ExpressionResolver {
    struct MutableArrayTarget {
        let elements: [SwiftValue]
        let writeBack: (([SwiftValue]) -> Void)?
    }

    func mutableArrayTarget(
        from baseValue: SwiftValue,
        functionName: String
    ) throws -> MutableArrayTarget {
        switch baseValue {
        case .state(let reference):
            let storage = reference.read()
            let elements = try extractArrayElements(from: storage, functionName: functionName)
            return MutableArrayTarget(
                elements: elements,
                writeBack: { newElements in
                    reference.write(self.wrapArrayValue(newElements, matching: storage))
                }
            )
        case .binding(let binding):
            let storage = binding.read()
            let elements = try extractArrayElements(from: storage, functionName: functionName)
            return MutableArrayTarget(
                elements: elements,
                writeBack: { newElements in
                    binding.write(self.wrapArrayValue(newElements, matching: storage))
                }
            )
        case .optional(let wrapped):
            guard let wrapped else {
                throw SwiftUIEvaluatorError.invalidArguments("\(functionName) cannot operate on nil optionals.")
            }
            return try mutableArrayTarget(from: wrapped, functionName: functionName)
        default:
            let elements = try arrayElements(from: baseValue, functionName: functionName)
            return MutableArrayTarget(elements: elements, writeBack: nil)
        }
    }

    func arrayElements(
        from value: SwiftValue,
        functionName: String
    ) throws -> [SwiftValue] {
        switch value {
        case .binding(let binding):
            return try extractArrayElements(from: binding.read(), functionName: functionName)
        default:
            return try extractArrayElements(
                from: value.resolvingStateReference(),
                functionName: functionName
            )
        }
    }

    func extractArrayElements(
        from storage: SwiftValue,
        functionName: String
    ) throws -> [SwiftValue] {
        switch storage {
        case .array(let elements):
            return elements
        case .optional(let wrapped):
            guard let wrapped else {
                throw SwiftUIEvaluatorError.invalidArguments("\(functionName) cannot operate on nil optionals.")
            }
            return try extractArrayElements(from: wrapped, functionName: functionName)
        default:
            throw SwiftUIEvaluatorError.invalidArguments("\(functionName) is only supported on arrays.")
        }
    }

    func wrapArrayValue(_ elements: [SwiftValue], matching template: SwiftValue) -> SwiftValue {
        let arrayValue: SwiftValue = .array(elements)
        switch template {
        case .optional(let wrapped):
            guard let wrapped else {
                return .optional(arrayValue)
            }
            return .optional(wrapArrayValue(elements, matching: wrapped))
        default:
            return arrayValue
        }
    }

    func shuffleElements(_ elements: [SwiftValue]) -> [SwiftValue] {
        guard elements.count > 1 else {
            return elements
        }

        var shuffled = elements
        var generator = SystemRandomNumberGenerator()
        for index in stride(from: shuffled.count - 1, through: 1, by: -1) {
            let random = Int(generator.next() % UInt64(index + 1))
            if index != random {
                shuffled.swapAt(index, random)
            }
        }

        if arraysEqual(shuffled, elements) {
            let reversed = Array(elements.reversed())
            if !arraysEqual(reversed, elements) {
                return reversed
            }
        }

        return shuffled
    }

    func arraysEqual(_ lhs: [SwiftValue], _ rhs: [SwiftValue]) -> Bool {
        guard lhs.count == rhs.count else { return false }
        for (left, right) in zip(lhs, rhs) {
            if !left.equals(right) {
                return false
            }
        }
        return true
    }
}
