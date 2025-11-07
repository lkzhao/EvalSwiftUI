import SwiftSyntax

public final class ExpressionResolver {
    public init() {}

    func resolveArguments(_ arguments: [ArgumentNode]) throws -> [ResolvedArgument] {
        try arguments.map { argument in
            ResolvedArgument(
                label: argument.label,
                value: try resolveExpression(argument.expression)
            )
        }
    }

    func resolveExpression(_ expression: ExprSyntax) throws -> SwiftValue {
        if let stringLiteral = expression.as(StringLiteralExprSyntax.self) {
            return .string(try stringLiteralValue(stringLiteral))
        }

        if let memberAccess = expression.as(MemberAccessExprSyntax.self) {
            return .memberAccess(try memberAccessPath(memberAccess))
        }

        if let reference = expression.as(DeclReferenceExprSyntax.self) {
            return .memberAccess([reference.baseName.text])
        }

        throw SwiftUIEvaluatorError.unsupportedExpression(expression.description)
    }

    private func memberAccessPath(_ memberAccess: MemberAccessExprSyntax) throws -> [String] {
        var components: [String] = [memberAccess.declName.baseName.text]
        var currentBase = memberAccess.base

        while let baseExpr = currentBase {
            if let nestedMember = baseExpr.as(MemberAccessExprSyntax.self) {
                components.insert(nestedMember.declName.baseName.text, at: 0)
                currentBase = nestedMember.base
            } else if let reference = baseExpr.as(DeclReferenceExprSyntax.self) {
                components.insert(reference.baseName.text, at: 0)
                break
            } else {
                throw SwiftUIEvaluatorError.unsupportedExpression(baseExpr.description)
            }
        }

        return components
    }

    private func stringLiteralValue(_ literal: StringLiteralExprSyntax) throws -> String {
        var result = ""

        for segment in literal.segments {
            if let stringSegment = segment.as(StringSegmentSyntax.self) {
                result.append(stringSegment.content.text)
            } else {
                throw SwiftUIEvaluatorError.invalidArguments("String interpolation is not supported.")
            }
        }

        return result
    }
}

public enum SwiftValue {
    case string(String)
    case memberAccess([String])
}
