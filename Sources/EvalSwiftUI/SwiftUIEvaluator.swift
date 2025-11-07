//
//  SwiftUIEvaluator.swift
//  EvalSwiftUI
//
//  Created by Luke Zhao on 11/7/25.
//

import SwiftSyntax
import SwiftUI

enum SwiftUIEvaluatorError: Error, LocalizedError {
    case missingRootExpression
    case unsupportedExpression(String)
    case invalidTextArguments
    case unsupportedModifier(String)
    case unsupportedFontArgument

    var errorDescription: String? {
        switch self {
        case .missingRootExpression:
            return "Expected a top-level expression."
        case .unsupportedExpression(let message):
            return "Unsupported expression: \(message)"
        case .invalidTextArguments:
            return "Only simple string literals are supported for Text()."
        case .unsupportedModifier(let name):
            return "Modifier .\(name)() is not supported."
        case .unsupportedFontArgument:
            return "Unsupported argument to font modifier."
        }
    }
}

class SwiftUIEvaluator {
    func evaluate(syntax: SourceFileSyntax) throws -> some View {
        guard let statement = syntax.statements.first,
              let call = statement.item.as(FunctionCallExprSyntax.self) else {
            throw SwiftUIEvaluatorError.missingRootExpression
        }
        return try evaluate(call: call)
    }

    private func evaluate(expr: ExprSyntax) throws -> AnyView {
        if let call = expr.as(FunctionCallExprSyntax.self) {
            return try evaluate(call: call)
        }
        throw SwiftUIEvaluatorError.unsupportedExpression(expr.description)
    }

    private func evaluate(call: FunctionCallExprSyntax) throws -> AnyView {
        if let memberAccess = call.calledExpression.as(MemberAccessExprSyntax.self) {
            guard let baseExpr = memberAccess.base else {
                throw SwiftUIEvaluatorError.unsupportedExpression(call.description)
            }

            let baseView = try evaluate(expr: baseExpr)
            let modifierName = memberAccess.declName.baseName.text
            return try apply(modifier: modifierName, arguments: call.arguments, to: baseView)
        }

        if let declRef = call.calledExpression.as(DeclReferenceExprSyntax.self) {
            switch declRef.baseName.text {
            case "Text":
                return try evaluateTextCall(call)
            default:
                break
            }
        }

        throw SwiftUIEvaluatorError.unsupportedExpression(call.description)
    }

    private func evaluateTextCall(_ call: FunctionCallExprSyntax) throws -> AnyView {
        guard call.arguments.count == 1,
              let literalExpr = call.arguments.first?.expression.as(StringLiteralExprSyntax.self) else {
            throw SwiftUIEvaluatorError.invalidTextArguments
        }

        let text = try stringLiteralValue(literalExpr)
        return AnyView(Text(text))
    }

    private func apply(modifier name: String,
                       arguments: LabeledExprListSyntax,
                       to baseView: AnyView) throws -> AnyView {
        switch name {
        case "font":
            guard arguments.count == 1,
                  let argExpr = arguments.first?.expression else {
                throw SwiftUIEvaluatorError.unsupportedFontArgument
            }
            let font = try parseFont(from: argExpr)
            return AnyView(baseView.font(font))
        case "padding":
            guard arguments.isEmpty else {
                throw SwiftUIEvaluatorError.unsupportedModifier(name)
            }
            return AnyView(baseView.padding())
        default:
            throw SwiftUIEvaluatorError.unsupportedModifier(name)
        }
    }

    private func parseFont(from expression: ExprSyntax) throws -> Font {
        if let memberAccess = expression.as(MemberAccessExprSyntax.self) {
            let name = memberAccess.declName.baseName.text
            if name == "title" {
                if let base = memberAccess.base?.as(DeclReferenceExprSyntax.self) {
                    if base.baseName.text == "Font" {
                        return .title
                    }
                } else if memberAccess.base == nil {
                    return .title
                }
            }
        }

        throw SwiftUIEvaluatorError.unsupportedFontArgument
    }

    private func stringLiteralValue(_ literal: StringLiteralExprSyntax) throws -> String {
        var result = ""

        for segment in literal.segments {
            if let stringSegment = segment.as(StringSegmentSyntax.self) {
                result.append(stringSegment.content.text)
            } else {
                // Interpolated strings are not supported yet.
                throw SwiftUIEvaluatorError.invalidTextArguments
            }
        }

        return result
    }
}
