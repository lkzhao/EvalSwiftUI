import SwiftSyntax

final class ViewNodeBuilder {
    func buildViewNode(from call: FunctionCallExprSyntax) throws -> ViewNode {
        if let memberAccess = call.calledExpression.as(MemberAccessExprSyntax.self) {
            guard let baseExpression = memberAccess.base,
                  let baseCall = baseExpression.as(FunctionCallExprSyntax.self) else {
                throw SwiftUIEvaluatorError.unsupportedExpression(call.description)
            }

            var node = try buildViewNode(from: baseCall)
            node.modifiers.append(
                ModifierNode(
                    name: memberAccess.declName.baseName.text,
                    arguments: parseArguments(call.arguments)
                )
            )
            return node
        }

        if let declRef = call.calledExpression.as(DeclReferenceExprSyntax.self) {
            return ViewNode(
                constructor: ViewConstructor(
                    name: declRef.baseName.text,
                    arguments: parseArguments(call.arguments)
                ),
                modifiers: []
            )
        }

        throw SwiftUIEvaluatorError.unsupportedExpression(call.description)
    }

    private func parseArguments(_ arguments: LabeledExprListSyntax) -> [ArgumentNode] {
        arguments.map { labeledExpr in
            ArgumentNode(
                label: labeledExpr.label?.text,
                expression: ExprSyntax(labeledExpr.expression)
            )
        }
    }
}
