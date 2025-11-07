import SwiftSyntax

public final class ExpressionResolver {
    public init() {}

    func resolveExpression(_ expression: ExprSyntax) throws -> SwiftValue {
        if let stringLiteral = expression.as(StringLiteralExprSyntax.self) {
            return .string(try stringLiteralValue(stringLiteral))
        }

        if let integerLiteral = expression.as(IntegerLiteralExprSyntax.self) {
            guard let value = Double(integerLiteral.literal.text) else {
                throw SwiftUIEvaluatorError.invalidArguments("Unable to parse integer literal \(integerLiteral.literal.text).")
            }
            return .number(value)
        }

        if let floatLiteral = expression.as(FloatLiteralExprSyntax.self) {
            guard let value = Double(floatLiteral.literal.text) else {
                throw SwiftUIEvaluatorError.invalidArguments("Unable to parse float literal \(floatLiteral.literal.text).")
            }
            return .number(value)
        }

        if let functionCall = expression.as(FunctionCallExprSyntax.self) {
            return try resolveFunctionCall(functionCall)
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

    private func resolveFunctionCall(_ call: FunctionCallExprSyntax) throws -> SwiftValue {
        let name: [String]
        if let memberAccess = call.calledExpression.as(MemberAccessExprSyntax.self) {
            name = try memberAccessPath(memberAccess)
        } else if let reference = call.calledExpression.as(DeclReferenceExprSyntax.self) {
            name = [reference.baseName.text]
        } else {
            throw SwiftUIEvaluatorError.unsupportedExpression(call.description)
        }

        let arguments = try resolveCallArguments(call.arguments)
        return .functionCall(FunctionCallValue(name: name, arguments: arguments))
    }

    private func resolveCallArguments(_ arguments: LabeledExprListSyntax) throws -> [ResolvedArgument] {
        try arguments.map { element in
            let value = try resolveExpression(ExprSyntax(element.expression))
            return ResolvedArgument(label: element.label?.text, value: value)
        }
    }
}
