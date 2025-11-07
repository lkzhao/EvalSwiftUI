import SwiftSyntax
import SwiftUI

final class SwiftUIEvaluator {
    private let viewNodeBuilder = ViewNodeBuilder()
    private let expressionResolver = ExpressionResolver()
    private lazy var viewRegistry = ViewRegistry(expressionResolver: expressionResolver)
    private lazy var modifierRegistry = ModifierRegistry(expressionResolver: expressionResolver)

    func evaluate(syntax: SourceFileSyntax) throws -> some View {
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
