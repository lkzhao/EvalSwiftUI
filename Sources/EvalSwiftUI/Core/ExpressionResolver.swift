import SwiftSyntax

public final class ExpressionResolver {
    private let defaultContext: (any SwiftUIEvaluatorContext)?

    public init(context: (any SwiftUIEvaluatorContext)? = nil) {
        self.defaultContext = context
    }

    func resolveExpression(
        _ expression: ExprSyntax,
        scope: ExpressionScope = [:],
        context externalContext: (any SwiftUIEvaluatorContext)? = nil
    ) throws -> SwiftValue {
        let context = externalContext ?? defaultContext
        if let stringLiteral = expression.as(StringLiteralExprSyntax.self) {
            return .string(try stringLiteralValue(stringLiteral, scope: scope, context: context))
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

        if let booleanLiteral = expression.as(BooleanLiteralExprSyntax.self) {
            return .bool(booleanLiteral.literal.text == "true")
        }

        if let functionCall = expression.as(FunctionCallExprSyntax.self) {
            return try resolveFunctionCall(functionCall, scope: scope, context: context)
        }

        if let memberAccess = expression.as(MemberAccessExprSyntax.self) {
            return .memberAccess(try memberAccessPath(memberAccess))
        }

        if let reference = expression.as(DeclReferenceExprSyntax.self) {
            if let scopedValue = scope[reference.baseName.text] {
                return scopedValue
            }
            if let externalValue = context?.value(for: reference.baseName.text) {
                return externalValue
            }
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

    private func stringLiteralValue(
        _ literal: StringLiteralExprSyntax,
        scope: ExpressionScope,
        context: (any SwiftUIEvaluatorContext)?
    ) throws -> String {
        var result = ""

        for segment in literal.segments {
            if let stringSegment = segment.as(StringSegmentSyntax.self) {
                result.append(stringSegment.content.text)
            } else if let interpolation = segment.as(ExpressionSegmentSyntax.self) {
                guard interpolation.expressions.count == 1,
                      let element = interpolation.expressions.first else {
                    throw SwiftUIEvaluatorError.invalidArguments("Only simple string interpolation expressions are supported.")
                }
                let value = try resolveExpression(
                    ExprSyntax(element.expression),
                    scope: scope,
                    context: context
                )
                result.append(try stringValue(from: value))
            } else {
                throw SwiftUIEvaluatorError.invalidArguments("String interpolation is not supported.")
            }
        }

        return result
    }

    private func resolveFunctionCall(
        _ call: FunctionCallExprSyntax,
        scope: ExpressionScope,
        context: (any SwiftUIEvaluatorContext)?
    ) throws -> SwiftValue {
        let name: [String]
        if let memberAccess = call.calledExpression.as(MemberAccessExprSyntax.self) {
            name = try memberAccessPath(memberAccess)
        } else if let reference = call.calledExpression.as(DeclReferenceExprSyntax.self) {
            name = [reference.baseName.text]
        } else {
            throw SwiftUIEvaluatorError.unsupportedExpression(call.description)
        }

        let arguments = try resolveCallArguments(call.arguments, scope: scope, context: context)
        return .functionCall(FunctionCallValue(name: name, arguments: arguments))
    }

    private func resolveCallArguments(
        _ arguments: LabeledExprListSyntax,
        scope: ExpressionScope,
        context: (any SwiftUIEvaluatorContext)?
    ) throws -> [ResolvedArgument] {
        try arguments.map { element in
            let value = try resolveExpression(
                ExprSyntax(element.expression),
                scope: scope,
                context: context
            )
            return ResolvedArgument(label: element.label?.text, value: value)
        }
    }

    private func stringValue(from value: SwiftValue) throws -> String {
        switch value {
        case .string(let string):
            return string
        case .number(let number):
            return number.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(number))
                : String(number)
        case .bool(let flag):
            return String(flag)
        default:
            throw SwiftUIEvaluatorError.invalidArguments(
                "String interpolation expects string, numeric, or boolean values, received \(value.typeDescription)."
            )
        }
    }
}
