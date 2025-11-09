import SwiftSyntax
import SwiftUI

final class SwiftUIViewRenderer: ViewRendering {
    private let viewRegistry: ViewRegistry
    private let memberFunctionRegistry: MemberFunctionRegistry
    private let expressionEvaluator: ExpressionEvaluating
    private unowned let evaluator: SwiftUIEvaluator
    private let context: (any SwiftUIEvaluatorContext)?

    init(viewRegistry: ViewRegistry,
         memberFunctionRegistry: MemberFunctionRegistry,
         expressionEvaluator: ExpressionEvaluating,
         evaluator: SwiftUIEvaluator,
         context: (any SwiftUIEvaluatorContext)?) {
        self.viewRegistry = viewRegistry
        self.memberFunctionRegistry = memberFunctionRegistry
        self.expressionEvaluator = expressionEvaluator
        self.evaluator = evaluator
        self.context = context
    }

    func render(nodes: [ViewNode]) throws -> AnyView {
        guard let last = nodes.last else {
            throw SwiftUIEvaluatorError.missingRootExpression
        }

        if nodes.count == 1 {
            return try render(node: last, overrides: .empty)
        }

        let rendered = try nodes.map { try render(node: $0, overrides: .empty) }
        return wrapInStack(rendered)
    }

    func render(node: ViewNode, overrides: ExpressionScope) throws -> AnyView {
        let mergedScope = node.scope.merging(overrides) { _, new in new }
        let resolvedConstructorArguments = try resolveArguments(node.constructor.arguments, scope: mergedScope)
        let view = try viewRegistry.makeView(
            from: node.constructor,
            arguments: resolvedConstructorArguments
        )
        var viewValue = SwiftValue.view(view)
        for modifier in node.modifiers {
            let resolvedModifierArguments = try resolveArguments(modifier.arguments, scope: mergedScope)
            viewValue = try memberFunctionRegistry.call(
                name: modifier.name,
                baseValue: viewValue,
                arguments: resolvedModifierArguments,
                context: DictionaryContext(scope: mergedScope)
            )
        }

        guard let finalView = viewValue.asAnyView() else {
            throw SwiftUIEvaluatorError.invalidArguments("Modifier chain did not resolve to a view value.")
        }
        return finalView
    }

    private func resolveArguments(_ arguments: [ArgumentNode], scope: ExpressionScope) throws -> [ResolvedArgument] {
        try arguments.map { argument in
            switch argument.value {
            case .expression(let expression):
                let value = try expressionEvaluator.resolveExpression(
                    expression,
                    scope: scope,
                    context: context
                )
                return ResolvedArgument(label: argument.label, value: value)
            case .closure(let closure, let capturedScope):
                let mergedScope = capturedScope.merging(scope) { _, new in new }
                let resolvedClosure = ResolvedClosure(
                    evaluator: evaluator,
                    closure: closure,
                    scope: mergedScope
                )
                return ResolvedArgument(label: argument.label, value: .closure(resolvedClosure))
            }
        }
    }

    private func wrapInStack(_ views: [AnyView]) -> AnyView {
        AnyView(
            VStack(alignment: .center, spacing: 0) {
                ForEach(Array(views.indices), id: \.self) { index in
                    views[index]
                }
            }
        )
    }
}
