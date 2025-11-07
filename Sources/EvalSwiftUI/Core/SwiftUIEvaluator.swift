import SwiftParser
import SwiftSyntax
import SwiftUI

public final class SwiftUIEvaluator {
    private let viewNodeBuilder = ViewNodeBuilder()
    private let expressionResolver: ExpressionResolver
    private let viewRegistry: ViewRegistry
    private let modifierRegistry: ModifierRegistry

    public init(expressionResolver: ExpressionResolver = ExpressionResolver(),
                viewBuilders: [any SwiftUIViewBuilder] = [],
                modifierBuilders: [any SwiftUIModifierBuilder] = []) {
        self.expressionResolver = expressionResolver
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

        let viewNode = try viewNodeBuilder.buildViewNode(from: call)
        return try buildView(from: viewNode)
    }

    private func buildView(from node: ViewNode) throws -> AnyView {
        let resolvedConstructorArguments = try resolveArguments(node.constructor.arguments)
        var view = try viewRegistry.makeView(
            from: node.constructor,
            arguments: resolvedConstructorArguments
        )
        for modifier in node.modifiers {
            let resolvedModifierArguments = try resolveArguments(modifier.arguments)
            view = try modifierRegistry.applyModifier(
                modifier,
                arguments: resolvedModifierArguments,
                to: view
            )
        }
        return view
    }

    private func resolveArguments(_ arguments: [ArgumentNode]) throws -> [ResolvedArgument] {
        try arguments.map { argument in
            switch argument.value {
            case .expression(let expression):
                let value = try expressionResolver.resolveExpression(expression)
                return ResolvedArgument(label: argument.label, value: value)
            case .closure(let closure):
                let content = try makeViewContent(from: closure)
                return ResolvedArgument(label: argument.label, value: .viewContent(content))
            }
        }
    }

    private func makeViewContent(from closure: ClosureExprSyntax) throws -> ViewContent {
        let nodes = try viewNodeBuilder.buildViewNodes(from: closure)
        let renderers = nodes.map { node in { try self.buildView(from: node) } }
        return ViewContent(renderers: renderers)
    }
}
