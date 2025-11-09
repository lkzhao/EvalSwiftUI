import SwiftSyntax

public final class ExpressionResolver {
    private let defaultContext: (any SwiftUIEvaluatorContext)?
    private let layers: [any ExpressionResolutionLayer]
    let memberFunctionRegistry: MemberFunctionRegistry

    public init(
        context: (any SwiftUIEvaluatorContext)? = nil
    ) {
        self.defaultContext = context
        self.layers = ExpressionResolver.defaultLayers()
        self.memberFunctionRegistry = MemberFunctionRegistry()
    }

    init(
        context: (any SwiftUIEvaluatorContext)? = nil,
        layers: [any ExpressionResolutionLayer],
        memberFunctionRegistry: MemberFunctionRegistry = MemberFunctionRegistry()
    ) {
        self.defaultContext = context
        self.layers = layers
        self.memberFunctionRegistry = memberFunctionRegistry
    }

    init(
        context: (any SwiftUIEvaluatorContext)? = nil,
        memberFunctionRegistry: MemberFunctionRegistry
    ) {
        self.defaultContext = context
        self.layers = ExpressionResolver.defaultLayers()
        self.memberFunctionRegistry = memberFunctionRegistry
    }

    func resolveExpression(
        _ expression: ExprSyntax,
        scope: ExpressionScope = [:],
        context externalContext: (any SwiftUIEvaluatorContext)? = nil
    ) throws -> SwiftValue {
        let context = externalContext ?? defaultContext

        if let collapsedTuple = expression.singleValueTuplePayload {
            return try resolveExpression(
                collapsedTuple,
                scope: scope,
                context: context
            )
        }

        for layer in layers {
            if let value = try layer.resolve(
                expression: expression,
                using: self,
                scope: scope,
                context: context
            ) {
                return value
            }
        }

        throw SwiftUIEvaluatorError.unsupportedExpression(expression.description)
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

    private static func defaultLayers() -> [any ExpressionResolutionLayer] {
        [
            LiteralExpressionLayer(),
            CollectionExpressionLayer(),
            SequenceExpressionLayer(),
            PrefixOperatorExpressionLayer(),
            KeyPathExpressionLayer(),
            FunctionCallExpressionLayer(),
            SubscriptExpressionLayer(),
            MemberAccessExpressionLayer(),
            DeclReferenceExpressionLayer()
        ]
    }
}

private extension ExprSyntax {
    var singleValueTuplePayload: ExprSyntax? {
        guard let tuple = self.as(TupleExprSyntax.self),
              tuple.elements.count == 1,
              let element = tuple.elements.first,
              element.label == nil else {
            return nil
        }
        return ExprSyntax(element.expression)
    }
}
