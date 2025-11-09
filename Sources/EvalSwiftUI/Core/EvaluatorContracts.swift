import SwiftSyntax
import SwiftUI

protocol ExpressionEvaluating {
    func resolveExpression(
        _ expression: ExprSyntax,
        scope: ExpressionScope,
        context: (any SwiftUIEvaluatorContext)?
    ) throws -> SwiftValue

    func resolveCallArguments(
        _ arguments: LabeledExprListSyntax,
        scope: ExpressionScope,
        context: (any SwiftUIEvaluatorContext)?
    ) throws -> [ResolvedArgument]

    func evaluateCompoundAssignment(
        symbol: String,
        lhs: SwiftValue,
        rhs: SwiftValue
    ) throws -> SwiftValue
}

protocol ViewRendering {
    func render(node: ViewNode, overrides: ExpressionScope) throws -> AnyView
    func render(nodes: [ViewNode]) throws -> AnyView
}

protocol MutationEvaluating {
    func process(variableDecl: VariableDeclSyntax,
                 scope: inout ExpressionScope,
                 allowStateDeclarations: Bool) throws

    func process(expression: ExprSyntax,
                 scope: inout ExpressionScope) throws -> Bool
}

protocol StateRegistry {
    func registerState(identifier: String, initialValue: SwiftValue) -> SwiftValue
}

protocol ModifierDispatching {
    func hasHandler(named name: String) -> Bool
    func call(
        name: String,
        baseValue: SwiftValue?,
        arguments: [ResolvedArgument],
        context: any SwiftUIEvaluatorContext
    ) throws -> SwiftValue
}
