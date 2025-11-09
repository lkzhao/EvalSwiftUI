import SwiftSyntax

struct ControlFlowLowerer {
    private let expressionResolver: ExpressionEvaluating
    private let context: (any SwiftUIEvaluatorContext)?

    init(expressionResolver: ExpressionEvaluating,
         context: (any SwiftUIEvaluatorContext)?) {
        self.expressionResolver = expressionResolver
        self.context = context
    }

    func lowerIf(
        _ ifExpr: IfExprSyntax,
        scope: ExpressionScope,
        build: (CodeBlockItemListSyntax, ExpressionScope) throws -> [ViewNode]
    ) throws -> [ViewNode] {
        guard ifExpr.conditions.count == 1, let condition = ifExpr.conditions.first else {
            throw SwiftUIEvaluatorError.invalidArguments("if statements support exactly one condition.")
        }

        switch condition.condition {
        case .expression(let conditionExpression):
            let value = try expressionResolver.resolveExpression(
                ExprSyntax(conditionExpression),
                scope: scope,
                context: context
            )

            guard case .bool(let isTrue) = value.payload else {
                throw SwiftUIEvaluatorError.invalidArguments("if conditions must resolve to a boolean value.")
            }

            if isTrue {
                return try build(ifExpr.body.statements, scope)
            }
            return try lowerElseBody(ifExpr.elseBody, scope: scope, build: build)

        case .optionalBinding(let binding):
            return try processOptionalBindingCondition(
                binding,
                body: ifExpr.body,
                elseBody: ifExpr.elseBody,
                scope: scope,
                build: build
            )
        default:
            throw SwiftUIEvaluatorError.invalidArguments("if statements only support boolean expressions or optional bindings.")
        }
    }

    private func processOptionalBindingCondition(
        _ binding: OptionalBindingConditionSyntax,
        body: CodeBlockSyntax,
        elseBody: IfExprSyntax.ElseBody?,
        scope: ExpressionScope,
        build: (CodeBlockItemListSyntax, ExpressionScope) throws -> [ViewNode]
    ) throws -> [ViewNode] {
        guard let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
            throw SwiftUIEvaluatorError.invalidArguments("if let requires an identifier pattern.")
        }

        let resolvedValue: SwiftValue
        if let initializer = binding.initializer {
            resolvedValue = try expressionResolver.resolveExpression(
                ExprSyntax(initializer.value),
                scope: scope,
                context: context
            )
        } else if let scopedValue = scope[identifierPattern.identifier.text] {
            resolvedValue = scopedValue
        } else if let externalValue = context?.value(for: identifierPattern.identifier.text) {
            resolvedValue = externalValue
        } else {
            throw SwiftUIEvaluatorError.invalidArguments("if let requires an initializer or an existing optional identifier.")
        }

        guard case .optional(let wrapped) = resolvedValue.payload else {
            throw SwiftUIEvaluatorError.invalidArguments("if let requires an optional value.")
        }

        guard let unwrapped = wrapped?.unwrappedOptional() else {
            return try lowerElseBody(elseBody, scope: scope, build: build)
        }

        var boundScope = scope
        boundScope.set(unwrapped, for: identifierPattern.identifier.text, origin: .local, mutable: true)
        return try build(body.statements, boundScope)
    }

    private func lowerElseBody(
        _ elseBody: IfExprSyntax.ElseBody?,
        scope: ExpressionScope,
        build: (CodeBlockItemListSyntax, ExpressionScope) throws -> [ViewNode]
    ) throws -> [ViewNode] {
        guard let elseBody else {
            return []
        }

        switch elseBody {
        case .ifExpr(let nested):
            return try lowerIf(nested, scope: scope, build: build)
        case .codeBlock(let block):
            return try build(block.statements, scope)
        }
    }

    func lowerSwitch(
        _ switchExpr: SwitchExprSyntax,
        scope: ExpressionScope,
        build: (CodeBlockItemListSyntax, ExpressionScope) throws -> [ViewNode]
    ) throws -> [ViewNode] {
        let subjectValue = try expressionResolver.resolveExpression(
            ExprSyntax(switchExpr.subject),
            scope: scope,
            context: context
        )

        for element in switchExpr.cases {
            guard let switchCase = element.as(SwitchCaseSyntax.self) else { continue }

            switch switchCase.label {
            case .case(let caseLabel):
                for caseItem in caseLabel.caseItems {
                    guard let caseScope = try matchCaseItem(caseItem, subject: subjectValue, scope: scope) else {
                        continue
                    }
                    return try build(switchCase.statements, caseScope)
                }
            case .default:
                return try build(switchCase.statements, scope)
            }
        }

        return []
    }

    private func matchCaseItem(
        _ caseItem: SwitchCaseItemSyntax,
        subject: SwiftValue,
        scope: ExpressionScope
    ) throws -> ExpressionScope? {
        guard let bindings = try matchPattern(caseItem.pattern, with: subject, scope: scope) else {
            return nil
        }

        var mergedScope = scope
        mergedScope.merge(bindings) { _, new in new }

        if let whereClause = caseItem.whereClause {
            let conditionValue = try expressionResolver.resolveExpression(
                ExprSyntax(whereClause.condition),
                scope: mergedScope,
                context: context
            )
            guard case .bool(let isTrue) = conditionValue.payload else {
                throw SwiftUIEvaluatorError.invalidArguments("switch case where clauses must resolve to a boolean value.")
            }
            guard isTrue else { return nil }
        }

        return mergedScope
    }

    private func matchPattern(
        _ pattern: PatternSyntax,
        with subject: SwiftValue,
        scope: ExpressionScope
    ) throws -> ExpressionScope? {
        if let bindingPattern = pattern.as(ValueBindingPatternSyntax.self) {
            return try matchValueBindingPattern(bindingPattern, subject: subject)
        }

        if pattern.is(WildcardPatternSyntax.self) {
            return ExpressionScope.empty
        }

        if let expressionPattern = pattern.as(ExpressionPatternSyntax.self) {
            let expectedValue = try expressionResolver.resolveExpression(
                ExprSyntax(expressionPattern.expression),
                scope: scope,
                context: context
            )
            return expectedValue.equals(subject) ? ExpressionScope.empty : nil
        }

        throw SwiftUIEvaluatorError.invalidArguments(
            "Unsupported switch pattern: \(pattern.trimmed.description)"
        )
    }

    private func matchValueBindingPattern(
        _ pattern: ValueBindingPatternSyntax,
        subject: SwiftValue
    ) throws -> ExpressionScope? {
        guard let identifierPattern = pattern.pattern.as(IdentifierPatternSyntax.self) else {
            if let expressionPattern = pattern.pattern.as(ExpressionPatternSyntax.self) {
                if let optionalExpression = expressionPattern.expression.as(OptionalChainingExprSyntax.self) {
                    if let reference = optionalExpression.expression.as(DeclReferenceExprSyntax.self) {
                        return try bindOptionalValue(named: reference.baseName.text, subject: subject)
                    }

                    if let patternExpr = optionalExpression.expression.as(PatternExprSyntax.self),
                       let identifierPattern = patternExpr.pattern.as(IdentifierPatternSyntax.self) {
                        return try bindOptionalValue(named: identifierPattern.identifier.text, subject: subject)
                    }

                    throw SwiftUIEvaluatorError.invalidArguments(
                        "Unsupported optional binding expression base: \(optionalExpression.expression.syntaxNodeType)"
                    )
                }

                throw SwiftUIEvaluatorError.invalidArguments(
                    "Unsupported expression pattern in switch binding: \(expressionPattern.expression.syntaxNodeType)"
                )
            }

            throw SwiftUIEvaluatorError.invalidArguments(
                "switch case bindings require identifier patterns, received \(pattern.pattern.syntaxNodeType)"
            )
        }

        let identifier = identifierPattern.identifier.text
        if identifierPattern.representsOptionalBinding {
            return try bindOptionalValue(named: identifier, subject: subject)
        }

        var scope = ExpressionScope.empty
        scope.set(subject, for: identifier)
        return scope
    }

    private func bindOptionalValue(named identifier: String, subject: SwiftValue) throws -> ExpressionScope? {
        guard case .optional(let wrapped) = subject.payload,
              let unwrapped = wrapped?.unwrappedOptional() else {
            return nil
        }
        var scope = ExpressionScope.empty
        scope.set(unwrapped, for: identifier)
        return scope
    }
}

private extension IdentifierPatternSyntax {
    var representsOptionalBinding: Bool {
        guard let trailing = unexpectedAfterIdentifier else {
            return false
        }
        return trailing.description.contains("?")
    }
}
