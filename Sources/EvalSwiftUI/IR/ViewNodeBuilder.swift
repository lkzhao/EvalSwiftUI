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
                    arguments: parseArguments(call)
                )
            )
            return node
        }

        if let declRef = call.calledExpression.as(DeclReferenceExprSyntax.self) {
            return ViewNode(
                constructor: ViewConstructor(
                    name: declRef.baseName.text,
                    arguments: parseArguments(call)
                ),
                modifiers: []
            )
        }

        throw SwiftUIEvaluatorError.unsupportedExpression(call.description)
    }

    func buildViewNodes(from closure: ClosureExprSyntax) throws -> [ViewNode] {
        var children: [ViewNode] = []
        for statement in closure.statements {
            guard let expr = statement.item.as(ExprSyntax.self),
                  let callExpr = expr.as(FunctionCallExprSyntax.self) else {
                throw SwiftUIEvaluatorError.unsupportedExpression(statement.description)
            }
            children.append(try buildViewNode(from: callExpr))
        }
        return children
    }

    private func parseArguments(_ call: FunctionCallExprSyntax) -> [ArgumentNode] {
        var arguments: [ArgumentNode] = call.arguments.map { labeledExpr in
            ArgumentNode(
                label: labeledExpr.label?.text,
                value: .expression(ExprSyntax(labeledExpr.expression))
            )
        }

        if let trailing = call.trailingClosure {
            arguments.append(
                ArgumentNode(
                    label: nil,
                    value: .closure(trailing)
                )
            )
        }

        for additional in call.additionalTrailingClosures {
            arguments.append(
                ArgumentNode(
                    label: additional.label.text,
                    value: .closure(additional.closure)
                )
            )
        }

        return arguments
    }
}
