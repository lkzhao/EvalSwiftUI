import SwiftSyntax

protocol ExpressionResolutionLayer {
    func resolve(
        expression: ExprSyntax,
        using resolver: ExpressionResolver,
        scope: ExpressionScope,
        context: (any SwiftUIEvaluatorContext)?
    ) throws -> SwiftValue?
}

struct LiteralExpressionLayer: ExpressionResolutionLayer {
    func resolve(
        expression: ExprSyntax,
        using resolver: ExpressionResolver,
        scope: ExpressionScope,
        context: (any SwiftUIEvaluatorContext)?
    ) throws -> SwiftValue? {
        if let stringLiteral = expression.as(StringLiteralExprSyntax.self) {
            return .string(try resolver.stringLiteralValue(stringLiteral, scope: scope, context: context))
        }

        if let ternaryExpr = expression.as(TernaryExprSyntax.self) {
            let conditionValue = try resolver.resolveExpression(
                ExprSyntax(ternaryExpr.condition),
                scope: scope,
                context: context
            )
            let isTrue = try resolver.boolValue(from: conditionValue)
            if isTrue {
                return try resolver.resolveExpression(
                    ExprSyntax(ternaryExpr.thenExpression),
                    scope: scope,
                    context: context
                )
            }
            return try resolver.resolveExpression(
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

        return nil
    }
}

struct CollectionExpressionLayer: ExpressionResolutionLayer {
    func resolve(
        expression: ExprSyntax,
        using resolver: ExpressionResolver,
        scope: ExpressionScope,
        context: (any SwiftUIEvaluatorContext)?
    ) throws -> SwiftValue? {
        if let arrayLiteral = expression.as(ArrayExprSyntax.self) {
            let elements = try arrayLiteral.elements.map { element in
                try resolver.resolveExpression(
                    ExprSyntax(element.expression),
                    scope: scope,
                    context: context
                )
            }
            return .array(elements)
        }

        if let dictionaryLiteral = expression.as(DictionaryExprSyntax.self) {
            return try resolver.dictionaryValue(from: dictionaryLiteral, scope: scope, context: context)
        }

        return nil
    }
}

struct SequenceExpressionLayer: ExpressionResolutionLayer {
    func resolve(
        expression: ExprSyntax,
        using resolver: ExpressionResolver,
        scope: ExpressionScope,
        context: (any SwiftUIEvaluatorContext)?
    ) throws -> SwiftValue? {
        guard let sequenceExpr = expression.as(SequenceExprSyntax.self) else {
            return nil
        }

        if let rangeValue = try resolver.resolveRangeExpression(
            sequenceExpr,
            scope: scope,
            context: context
        ) {
            return .range(rangeValue)
        }

        return try resolver.resolveOperatorSequence(
            sequenceExpr,
            scope: scope,
            context: context
        )
    }
}

struct PrefixOperatorExpressionLayer: ExpressionResolutionLayer {
    func resolve(
        expression: ExprSyntax,
        using resolver: ExpressionResolver,
        scope: ExpressionScope,
        context: (any SwiftUIEvaluatorContext)?
    ) throws -> SwiftValue? {
        guard let prefixExpr = expression.as(PrefixOperatorExprSyntax.self) else {
            return nil
        }

        return try resolver.resolvePrefixOperator(
            prefixExpr,
            scope: scope,
            context: context
        )
    }
}

struct KeyPathExpressionLayer: ExpressionResolutionLayer {
    func resolve(
        expression: ExprSyntax,
        using resolver: ExpressionResolver,
        scope: ExpressionScope,
        context: (any SwiftUIEvaluatorContext)?
    ) throws -> SwiftValue? {
        guard let keyPathExpr = expression.as(KeyPathExprSyntax.self) else {
            return nil
        }
        return .keyPath(try resolver.keyPathValue(from: keyPathExpr))
    }
}

struct FunctionCallExpressionLayer: ExpressionResolutionLayer {
    func resolve(
        expression: ExprSyntax,
        using resolver: ExpressionResolver,
        scope: ExpressionScope,
        context: (any SwiftUIEvaluatorContext)?
    ) throws -> SwiftValue? {
        guard let call = expression.as(FunctionCallExprSyntax.self) else {
            return nil
        }
        return try resolver.resolveFunctionCall(
            call,
            scope: scope,
            context: context
        )
    }
}

struct SubscriptExpressionLayer: ExpressionResolutionLayer {
    func resolve(
        expression: ExprSyntax,
        using resolver: ExpressionResolver,
        scope: ExpressionScope,
        context: (any SwiftUIEvaluatorContext)?
    ) throws -> SwiftValue? {
        guard let subscriptExpr = expression.as(SubscriptCallExprSyntax.self) else {
            return nil
        }
        return try resolver.resolveSubscriptExpression(
            subscriptExpr,
            scope: scope,
            context: context
        )
    }
}

struct MemberAccessExpressionLayer: ExpressionResolutionLayer {
    func resolve(
        expression: ExprSyntax,
        using resolver: ExpressionResolver,
        scope: ExpressionScope,
        context: (any SwiftUIEvaluatorContext)?
    ) throws -> SwiftValue? {
        guard let memberAccess = expression.as(MemberAccessExprSyntax.self) else {
            return nil
        }
        return .memberAccess(try resolver.memberAccessPath(memberAccess))
    }
}

struct DeclReferenceExpressionLayer: ExpressionResolutionLayer {
    func resolve(
        expression: ExprSyntax,
        using resolver: ExpressionResolver,
        scope: ExpressionScope,
        context: (any SwiftUIEvaluatorContext)?
    ) throws -> SwiftValue? {
        guard let reference = expression.as(DeclReferenceExprSyntax.self) else {
            return nil
        }

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
}
