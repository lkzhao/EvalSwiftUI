import SwiftSyntax

public final class ExpressionResolver {
    private let defaultContext: (any SwiftUIEvaluatorContext)?
    private let layers: [any ExpressionResolutionLayer]
    let memberFunctionRegistry: MemberFunctionRegistry
    private var stateStore: RuntimeStateStore?

    public init(
        context: (any SwiftUIEvaluatorContext)? = nil,
        stateStore: RuntimeStateStore? = nil
    ) {
        self.defaultContext = context
        self.layers = ExpressionResolver.defaultLayers()
        self.memberFunctionRegistry = MemberFunctionRegistry()
        self.stateStore = stateStore
    }

    init(
        context: (any SwiftUIEvaluatorContext)? = nil,
        layers: [any ExpressionResolutionLayer],
        memberFunctionRegistry: MemberFunctionRegistry = MemberFunctionRegistry(),
        stateStore: RuntimeStateStore? = nil
    ) {
        self.defaultContext = context
        self.layers = layers
        self.memberFunctionRegistry = memberFunctionRegistry
        self.stateStore = stateStore
    }

    init(
        context: (any SwiftUIEvaluatorContext)? = nil,
        memberFunctionRegistry: MemberFunctionRegistry,
        stateStore: RuntimeStateStore? = nil
    ) {
        self.defaultContext = context
        self.layers = ExpressionResolver.defaultLayers()
        self.memberFunctionRegistry = memberFunctionRegistry
        self.stateStore = stateStore
    }

    func attach(stateStore: RuntimeStateStore) {
        self.stateStore = stateStore
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
