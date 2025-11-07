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
        viewRegistry = ViewRegistry(
            expressionResolver: expressionResolver,
            additionalBuilders: viewBuilders
        )
        modifierRegistry = ModifierRegistry(
            expressionResolver: expressionResolver,
            additionalBuilders: modifierBuilders
        )
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
        var view = try viewRegistry.makeView(from: node.constructor)
        for modifier in node.modifiers {
            view = try modifierRegistry.applyModifier(modifier, to: view)
        }
        return view
    }
}
