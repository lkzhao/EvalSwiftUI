import SwiftParser
import SwiftSyntax
import SwiftUI

public final class SwiftUIEvaluator {
    private let stateStore = RuntimeStateStore()
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
        viewNodeBuilder = ViewNodeBuilder(
            expressionResolver: resolver,
            context: context,
            stateStore: stateStore
        )
        viewRegistry = ViewRegistry(additionalBuilders: viewBuilders)
        modifierRegistry = ModifierRegistry(additionalBuilders: modifierBuilders)
    }

    public func evaluate(source: String) throws -> some View {
        let syntax = Parser.parse(source: source)
        return try evaluate(syntax: syntax)
    }

    private func evaluate(syntax: SourceFileSyntax) throws -> some View {
        stateStore.reset()
        let result = try viewNodeBuilder.buildViewNodes(in: syntax.statements, scope: [:])
        guard let viewNode = result.nodes.last else {
            throw SwiftUIEvaluatorError.missingRootExpression
        }

        if result.nodes.count > 1 {
            throw SwiftUIEvaluatorError.invalidArguments("Expected exactly one root view expression.")
        }

        return try buildView(from: viewNode)
    }

    private func buildView(from node: ViewNode, scopeOverrides: ExpressionScope = [:]) throws -> AnyView {
        let scope = node.scope.merging(scopeOverrides) { _, new in new }
        let resolvedConstructorArguments = try resolveArguments(node.constructor.arguments, scope: scope)
        var view = try viewRegistry.makeView(
            from: node.constructor,
            arguments: resolvedConstructorArguments
        )
        for modifier in node.modifiers {
            let resolvedModifierArguments = try resolveArguments(modifier.arguments, scope: scope)
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
        let parameterNames = closureParameterNames(closure)
        let renderers = nodes.map { node in
            { overrides in
                try self.buildView(from: node, scopeOverrides: overrides)
            }
        }
        return ViewContent(renderers: renderers, parameters: parameterNames)
    }

    private func closureParameterNames(_ closure: ClosureExprSyntax) -> [String] {
        guard let parameterClause = closure.signature?.parameterClause else {
            return []
        }

        switch parameterClause {
        case .parameterClause(let clause):
            return clause.parameters.map { parameter in
                if let secondName = parameter.secondName {
                    return secondName.text
                }
                return parameter.firstName.text
            }
        case .simpleInput(let shorthand):
            return shorthand.map { $0.name.text }
        }
    }
}
