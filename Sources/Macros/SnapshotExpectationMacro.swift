import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct SnapshotMacroError: Error, CustomStringConvertible {
    let description: String
    init(_ message: String) { self.description = message }
}

public struct SnapshotExpectationMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        guard let expansion = node.as(MacroExpansionExprSyntax.self) else {
            throw SnapshotMacroError("#expectSnapshot can only be used as an expression macro.")
        }

        guard let viewArgument = expansion.arguments.first(where: { $0.label == nil }) else {
            throw SnapshotMacroError("#expectSnapshot requires a view expression as its first argument.")
        }

        let sourceLiteral = ExprSyntax(StringLiteralExprSyntax(content: viewArgument.expression.trimmedDescription))

        let arguments = LabeledExprListSyntax([
            LabeledExprSyntax(
                label: .identifier("source"),
                colon: .colonToken(trailingTrivia: .space),
                expression: sourceLiteral
            )
        ])

        let closure = ClosureExprSyntax(statements: CodeBlockItemListSyntax {
            viewArgument.expression.trimmed
        })

        let calledExpression = DeclReferenceExprSyntax(baseName: .identifier("assertSnapshotsMatch"))

        let functionCall = FunctionCallExprSyntax(
            calledExpression: ExprSyntax(calledExpression),
            leftParen: .leftParenToken(),
            arguments: arguments,
            rightParen: .rightParenToken(),
            trailingClosure: closure
        )

        let tryExpression = TryExprSyntax(
            tryKeyword: .keyword(.try, trailingTrivia: .space),
            expression: functionCall
        )

        return ExprSyntax(tryExpression)
    }
}
