import Foundation
import SwiftSyntax
import SwiftUI

struct ViewNode {
    let constructor: ViewConstructor
    var modifiers: [ModifierNode]
    let scope: ExpressionScope
}

struct ViewConstructor {
    let name: String
    let arguments: [ArgumentNode]
}

struct ModifierNode {
    let name: String
    let arguments: [ArgumentNode]
}

struct ArgumentNode {
    enum Value {
        case expression(ExprSyntax)
        case closure(ClosureExprSyntax, scope: ExpressionScope)
    }

    let label: String?
    let value: Value
}

public struct ResolvedArgument {
    public let label: String?
    public let value: SwiftValue
}

public struct ResolvedClosure {
    private unowned let evaluator: SwiftUIEvaluator
    private let closure: ClosureExprSyntax
    private let scope: ExpressionScope

    init(evaluator: SwiftUIEvaluator,
         closure: ClosureExprSyntax,
         scope: ExpressionScope) {
        self.evaluator = evaluator
        self.closure = closure
        self.scope = scope
    }

    func makeViewContent() throws -> ViewContent {
        try evaluator.makeViewContent(from: closure, scope: scope)
    }

    var identifier: String {
        closure.description
    }

    func renderViews(
        using content: ViewContent,
        overriding overrides: ExpressionScope,
        inlineNamespace: [String]
    ) throws -> [AnyView] {
        try evaluator.withInlineInstanceNamespace(inlineNamespace) {
            try content.renderViews(overriding: overrides)
        }
    }

    func makeActionContent() -> ActionContent {
        ActionContent(evaluator: evaluator, closure: closure, scope: scope)
    }
}

public struct ActionContent: @unchecked Sendable {
    private unowned let evaluator: SwiftUIEvaluator
    private let closure: ClosureExprSyntax
    private let scope: ExpressionScope

    init(evaluator: SwiftUIEvaluator,
         closure: ClosureExprSyntax,
         scope: ExpressionScope) {
        self.evaluator = evaluator
        self.closure = closure
        self.scope = scope
    }

    func perform(overriding overrides: ExpressionScope = [:]) throws {
        try evaluator.performAction(from: closure, scope: scope, overrides: overrides)
    }
}
