import SwiftSyntax
import SwiftSyntaxBuilder

final class ViewNodeBuilder {
    private let expressionResolver: ExpressionEvaluating
    private let context: (any SwiftUIEvaluatorContext)?
    private let mutationEvaluator: MutationEvaluating
    private let controlFlowLowerer: ControlFlowLowerer

    init(expressionResolver: ExpressionEvaluating,
         context: (any SwiftUIEvaluatorContext)? = nil,
         mutationEvaluator: MutationEvaluating) {
        self.expressionResolver = expressionResolver
        self.context = context
        self.mutationEvaluator = mutationEvaluator
        self.controlFlowLowerer = ControlFlowLowerer(expressionResolver: expressionResolver, context: context)
    }

    func lower(
        statements: CodeBlockItemListSyntax,
        scope: ExpressionScope,
        allowStateDeclarations: Bool
    ) throws -> [ViewNode] {
        try buildViewNodes(in: statements, scope: scope, allowStateDeclarations: allowStateDeclarations)
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

    private func buildViewNodes(
        in statements: CodeBlockItemListSyntax,
        scope: ExpressionScope,
        allowStateDeclarations: Bool
    ) throws -> [ViewNode] {
        var children: [ViewNode] = []
        var currentScope = scope

        for statement in statements {
            if let variableDecl = statement.item.as(VariableDeclSyntax.self) {
                try mutationEvaluator.process(
                    variableDecl: variableDecl,
                    scope: &currentScope,
                    allowStateDeclarations: allowStateDeclarations
                )
                continue
            }

            guard let expr = expression(from: statement.item) else {
                throw SwiftUIEvaluatorError.unsupportedExpression(statement.description)
            }

            if try mutationEvaluator.process(expression: expr, scope: &currentScope) {
                continue
            }

            if let ifExpr = expr.as(IfExprSyntax.self) {
                let nodes = try controlFlowLowerer.lowerIf(ifExpr, scope: currentScope) { body, scope in
                    try self.buildViewNodes(
                        in: body,
                        scope: scope,
                        allowStateDeclarations: false
                    )
                }
                children.append(contentsOf: nodes)
                continue
            }

            if let switchExpr = expr.as(SwitchExprSyntax.self) {
                let nodes = try controlFlowLowerer.lowerSwitch(switchExpr, scope: currentScope) { body, scope in
                    try self.buildViewNodes(
                        in: body,
                        scope: scope,
                        allowStateDeclarations: false
                    )
                }
                children.append(contentsOf: nodes)
                continue
            }

            if let callExpr = expr.as(FunctionCallExprSyntax.self) {
                children.append(try buildViewNode(from: callExpr, scope: currentScope))
                continue
            }

            throw SwiftUIEvaluatorError.unsupportedExpression(statement.description)
        }

        return children
    }

    private func expression(from item: CodeBlockItemSyntax.Item) -> ExprSyntax? {
        if let expr = item.as(ExprSyntax.self) {
            return expr
        }

        if let expressionStatement = item.as(ExpressionStmtSyntax.self) {
            return ExprSyntax(expressionStatement.expression)
        }

        return nil
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
}
