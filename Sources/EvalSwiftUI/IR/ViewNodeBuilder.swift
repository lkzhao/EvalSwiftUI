import SwiftSyntax

final class ViewNodeBuilder {
    private let expressionResolver: ExpressionResolver
    private let context: (any SwiftUIEvaluatorContext)?

    init(expressionResolver: ExpressionResolver, context: (any SwiftUIEvaluatorContext)? = nil) {
        self.expressionResolver = expressionResolver
        self.context = context
    }

    func buildViewNode(from call: FunctionCallExprSyntax, scope: ExpressionScope) throws -> ViewNode {
        if let memberAccess = call.calledExpression.as(MemberAccessExprSyntax.self) {
            guard let baseExpression = memberAccess.base,
                  let baseCall = baseExpression.as(FunctionCallExprSyntax.self) else {
                throw SwiftUIEvaluatorError.unsupportedExpression(call.description)
            }

            var node = try buildViewNode(from: baseCall, scope: scope)
            node.modifiers.append(
                ModifierNode(
                    name: memberAccess.declName.baseName.text,
                    arguments: parseArguments(call, scope: scope)
                )
            )
            return node
        }

        if let declRef = call.calledExpression.as(DeclReferenceExprSyntax.self) {
            return ViewNode(
                constructor: ViewConstructor(
                    name: declRef.baseName.text,
                    arguments: parseArguments(call, scope: scope)
                ),
                modifiers: [],
                scope: scope
            )
        }

        throw SwiftUIEvaluatorError.unsupportedExpression(call.description)
    }

    func buildViewNodes(from closure: ClosureExprSyntax, scope: ExpressionScope) throws -> [ViewNode] {
        var children: [ViewNode] = []
        var currentScope = scope
        for statement in closure.statements {
            if let variableDecl = statement.item.as(VariableDeclSyntax.self) {
                currentScope = try processVariableDecl(variableDecl, scope: currentScope)
                continue
            }

            if let expr = statement.item.as(ExprSyntax.self),
               let callExpr = expr.as(FunctionCallExprSyntax.self) {
                children.append(try buildViewNode(from: callExpr, scope: currentScope))
                continue
            }

            throw SwiftUIEvaluatorError.unsupportedExpression(statement.description)
        }
        return children
    }

    private func parseArguments(_ call: FunctionCallExprSyntax, scope: ExpressionScope) -> [ArgumentNode] {
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
                    value: .closure(trailing, scope: scope)
                )
            )
        }

        for additional in call.additionalTrailingClosures {
            arguments.append(
                ArgumentNode(
                    label: additional.label.text,
                    value: .closure(additional.closure, scope: scope)
                )
            )
        }

        return arguments
    }

    private func processVariableDecl(_ decl: VariableDeclSyntax, scope: ExpressionScope) throws -> ExpressionScope {
        var updatedScope = scope
        for binding in decl.bindings {
            guard let namePattern = binding.pattern.as(IdentifierPatternSyntax.self),
                  let initializer = binding.initializer else {
                throw SwiftUIEvaluatorError.unsupportedExpression(decl.description)
            }

            let value = try expressionResolver.resolveExpression(
                ExprSyntax(initializer.value),
                scope: updatedScope,
                context: context
            )
            updatedScope[namePattern.identifier.text] = value
        }
        return updatedScope
    }
}
