import SwiftParser
import SwiftSyntax
import SwiftUI

public final class SwiftUIEvaluator {
    private let viewNodeBuilder: ViewNodeBuilder
    private let expressionResolver: ExpressionResolver
    private let viewRegistry: ViewRegistry
    private let modifierRegistry: ModifierRegistry
    private let context: (any SwiftUIEvaluatorContext)?

    public init(expressionResolver: ExpressionResolver? = nil,
                viewBuilders: [any SwiftUIViewBuilder] = [],
                modifierBuilders: [any SwiftUIModifierBuilder] = [],
                context: (any SwiftUIEvaluatorContext)? = nil) {
        self.context = context
        let resolver = expressionResolver ?? ExpressionResolver(context: context)
        self.expressionResolver = resolver
        viewNodeBuilder = ViewNodeBuilder(expressionResolver: resolver, context: context)
        viewRegistry = ViewRegistry(additionalBuilders: viewBuilders)
        modifierRegistry = ModifierRegistry(additionalBuilders: modifierBuilders)
    }

    public func evaluate(source: String) throws -> some View {
        let syntax = Parser.parse(source: source)
        return try evaluate(syntax: syntax)
    }

    private func evaluate(syntax: SourceFileSyntax) throws -> some View {
        guard let statement = syntax.statements.first,
              let call = statement.item.as(FunctionCallExprSyntax.self) else {
            throw SwiftUIEvaluatorError.missingRootExpression
        }

        let viewNode = try viewNodeBuilder.buildViewNode(from: call, scope: [:])
        return try buildView(from: viewNode)
    }

    private func buildView(from node: ViewNode) throws -> AnyView {
        let resolvedConstructorArguments = try resolveArguments(node.constructor.arguments, scope: node.scope)
        var view = try viewRegistry.makeView(
            from: node.constructor,
            arguments: resolvedConstructorArguments
        )
        for modifier in node.modifiers {
            let resolvedModifierArguments = try resolveArguments(modifier.arguments, scope: node.scope)
            view = try modifierRegistry.applyModifier(
                modifier,
                arguments: resolvedModifierArguments,
                to: view
            )
        }
        return view
    }

    private func resolveArguments(_ arguments: [ArgumentNode], scope: ExpressionScope) throws -> [ResolvedArgument] {
        try arguments.map { argument in
            switch argument.value {
            case .expression(let expression):
                let value = try expressionResolver.resolveExpression(
                    expression,
                    scope: scope,
                    context: context
                )
                return ResolvedArgument(label: argument.label, value: value)
            case .closure(let closure, let capturedScope):
                let content = try makeViewContent(from: closure, scope: capturedScope)
                return ResolvedArgument(label: argument.label, value: .viewContent(content))
            }
        }
    }

    private func makeViewContent(from closure: ClosureExprSyntax, scope: ExpressionScope) throws -> ViewContent {
        let nodes = try viewNodeBuilder.buildViewNodes(from: closure, scope: scope)
        let renderers = nodes.map { node in { try self.buildView(from: node) } }
        return ViewContent(renderers: renderers)
    }
}
