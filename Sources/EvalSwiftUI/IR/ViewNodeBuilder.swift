import SwiftSyntax
import SwiftSyntaxBuilder

final class ViewNodeBuilder {
    private let expressionResolver: ExpressionResolver
    private let context: (any SwiftUIEvaluatorContext)?
    private let stateStore: RuntimeStateStore
    private static let compoundAssignmentOperators: Set<String> = ["+=", "-=", "*=", "/="]

    init(expressionResolver: ExpressionResolver,
         context: (any SwiftUIEvaluatorContext)? = nil,
         stateStore: RuntimeStateStore) {
        self.expressionResolver = expressionResolver
        self.context = context
        self.stateStore = stateStore
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
        try buildViewNodes(in: closure.statements, scope: scope, allowStateDeclarations: false).nodes
    }

    func buildViewNodes(
        in statements: CodeBlockItemListSyntax,
        scope: ExpressionScope,
        allowStateDeclarations: Bool
    ) throws -> (nodes: [ViewNode], scope: ExpressionScope) {
        var children: [ViewNode] = []
        var currentScope = scope

        for statement in statements {
            if let variableDecl = statement.item.as(VariableDeclSyntax.self) {
                currentScope = try processVariableDecl(
                    variableDecl,
                    scope: currentScope,
                    allowStateDeclarations: allowStateDeclarations
                )
                continue
            }

            if let expr = expression(from: statement.item) {
                if try processMutationExpression(expr, scope: &currentScope) {
                    continue
                }
                if let ifExpr = expr.as(IfExprSyntax.self) {
                    let nodes = try processIfExpression(ifExpr, scope: currentScope)
                    children.append(contentsOf: nodes)
                    continue
                }

                if let switchExpr = expr.as(SwitchExprSyntax.self) {
                    let nodes = try processSwitchExpression(switchExpr, scope: currentScope)
                    children.append(contentsOf: nodes)
                    continue
                }

                if let callExpr = expr.as(FunctionCallExprSyntax.self) {
                    children.append(try buildViewNode(from: callExpr, scope: currentScope))
                    continue
                }
            }

            throw SwiftUIEvaluatorError.unsupportedExpression(statement.description)
        }

        return (children, currentScope)
    }

    private func processSwitchExpression(_ switchExpr: SwitchExprSyntax, scope: ExpressionScope) throws -> [ViewNode] {
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
                    return try buildViewNodes(
                        in: switchCase.statements,
                        scope: caseScope,
                        allowStateDeclarations: false
                    ).nodes
                }
            case .default:
                return try buildViewNodes(
                    in: switchCase.statements,
                    scope: scope,
                    allowStateDeclarations: false
                ).nodes
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
            guard case .bool(let isTrue) = conditionValue else {
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
            return [:]
        }

        if let expressionPattern = pattern.as(ExpressionPatternSyntax.self) {
            let expectedValue = try expressionResolver.resolveExpression(
                ExprSyntax(expressionPattern.expression),
                scope: scope,
                context: context
            )
            return expectedValue.equals(subject) ? [:] : nil
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

        return [identifier: subject]
    }

    private func bindOptionalValue(named identifier: String, subject: SwiftValue) throws -> ExpressionScope? {
        guard case .optional(let wrapped) = subject,
              let unwrapped = wrapped?.unwrappedOptional() else {
            return nil
        }
        return [identifier: unwrapped]
    }

    private func processIfExpression(_ ifExpr: IfExprSyntax, scope: ExpressionScope) throws -> [ViewNode] {
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

            guard case .bool(let isTrue) = value else {
                throw SwiftUIEvaluatorError.invalidArguments("if conditions must resolve to a boolean value.")
            }

            if isTrue {
                return try buildViewNodes(
                    in: ifExpr.body.statements,
                    scope: scope,
                    allowStateDeclarations: false
                ).nodes
            }

            return try buildElseBody(ifExpr.elseBody, scope: scope)

        case .optionalBinding(let binding):
            return try processOptionalBindingCondition(binding, body: ifExpr.body, elseBody: ifExpr.elseBody, scope: scope)
        default:
            throw SwiftUIEvaluatorError.invalidArguments("if statements only support boolean expressions or optional bindings.")
        }
    }

    private func processOptionalBindingCondition(
        _ binding: OptionalBindingConditionSyntax,
        body: CodeBlockSyntax,
        elseBody: IfExprSyntax.ElseBody?,
        scope: ExpressionScope
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

        guard case .optional(let wrapped) = resolvedValue else {
            throw SwiftUIEvaluatorError.invalidArguments("if let requires an optional value.")
        }

        guard let unwrapped = wrapped?.unwrappedOptional() else {
            return try buildElseBody(elseBody, scope: scope)
        }

        var boundScope = scope
        boundScope[identifierPattern.identifier.text] = unwrapped
        return try buildViewNodes(
            in: body.statements,
            scope: boundScope,
            allowStateDeclarations: false
        ).nodes
    }

    private func buildElseBody(_ elseBody: IfExprSyntax.ElseBody?, scope: ExpressionScope) throws -> [ViewNode] {
        guard let elseBody else {
            return []
        }

        switch elseBody {
        case .ifExpr(let nested):
            return try processIfExpression(nested, scope: scope)
        case .codeBlock(let block):
            return try buildViewNodes(
                in: block.statements,
                scope: scope,
                allowStateDeclarations: false
            ).nodes
        }
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

    private func processVariableDecl(
        _ decl: VariableDeclSyntax,
        scope: ExpressionScope,
        allowStateDeclarations: Bool
    ) throws -> ExpressionScope {
        var updatedScope = scope
        let hasStateAttribute = decl.attributes.containsStateAttribute
        for binding in decl.bindings {
            guard let namePattern = binding.pattern.as(IdentifierPatternSyntax.self),
                  let initializer = binding.initializer else {
                throw SwiftUIEvaluatorError.unsupportedExpression(decl.description)
            }

            var value = try expressionResolver.resolveExpression(
                ExprSyntax(initializer.value),
                scope: updatedScope,
                context: context
            )
            if !hasStateAttribute {
                value = value.resolvingStateReference()
            }
            if isOptional(binding) && !value.isOptional {
                value = .optional(value)
            }
            if hasStateAttribute {
                guard allowStateDeclarations else {
                    throw SwiftUIEvaluatorError.invalidArguments("@State declarations are only supported at the top level.")
                }
                updatedScope[namePattern.identifier.text] = registerStateVariable(
                    named: namePattern.identifier.text,
                    initialValue: value
                )
                continue
            }
            updatedScope[namePattern.identifier.text] = value
        }
        return updatedScope
    }

    private func registerStateVariable(named identifier: String, initialValue: SwiftValue) -> SwiftValue {
        let resolvedValue = initialValue.resolvingStateReference()
        let reference = stateStore.makeState(identifier: identifier, initialValue: resolvedValue)
        return .state(reference)
    }

    private func processMutationExpression(_ expression: ExprSyntax, scope: inout ExpressionScope) throws -> Bool {
        guard let sequence = expression.as(SequenceExprSyntax.self) else {
            return false
        }

        if try processAssignmentSequence(sequence, scope: &scope) {
            return true
        }

        if try processCompoundAssignmentSequence(sequence, scope: &scope) {
            return true
        }

        return false
    }

    private func processAssignmentSequence(_ sequence: SequenceExprSyntax, scope: inout ExpressionScope) throws -> Bool {
        let elements = Array(sequence.elements)
        guard elements.count >= 3 else {
            return false
        }

        guard elements.indices.contains(1), elements[1].is(AssignmentExprSyntax.self) else {
            return false
        }

        guard let identifier = elements[0].as(DeclReferenceExprSyntax.self) else {
            throw SwiftUIEvaluatorError.invalidArguments("Assignments require identifier targets.")
        }

        let rhsElements = elements[2...]
        let rhsExpression = try expression(from: rhsElements)
        let rhsValue = try expressionResolver.resolveExpression(
            rhsExpression,
            scope: scope,
            context: context
        )
        try assignValue(rhsValue, to: identifier.baseName.text, scope: &scope)
        return true
    }

    private func processCompoundAssignmentSequence(_ sequence: SequenceExprSyntax, scope: inout ExpressionScope) throws -> Bool {
        let elements = Array(sequence.elements)
        guard elements.count >= 3 else {
            return false
        }

        guard let operatorExpr = elements[1].as(BinaryOperatorExprSyntax.self) else {
            return false
        }

        let symbol = operatorExpr.operator.text
        guard Self.compoundAssignmentOperators.contains(symbol) else {
            return false
        }

        guard let identifier = elements[0].as(DeclReferenceExprSyntax.self) else {
            throw SwiftUIEvaluatorError.invalidArguments("Assignments require identifier targets.")
        }

        let rhsExpression = try expression(from: elements[2...])
        let rhsValue = try expressionResolver.resolveExpression(
            rhsExpression,
            scope: scope,
            context: context
        )
        let currentValue = try currentValue(for: identifier.baseName.text, scope: scope)
        let newValue = try expressionResolver.evaluateCompoundAssignment(
            symbol: symbol,
            lhs: currentValue,
            rhs: rhsValue
        )
        try assignValue(newValue, to: identifier.baseName.text, scope: &scope)
        return true
    }

    private func expression(from elements: ArraySlice<ExprSyntax>) throws -> ExprSyntax {
        guard let first = elements.first else {
            throw SwiftUIEvaluatorError.invalidArguments("Assignment requires a right-hand expression.")
        }

        if elements.count == 1 {
            return first
        }

        return ExprSyntax(
            SequenceExprSyntax {
                for element in elements {
                    element
                }
            }
        )
    }

    private func currentValue(for identifier: String, scope: ExpressionScope) throws -> SwiftValue {
        if let scoped = scope[identifier] {
            return scoped.resolvingStateReference()
        }
        throw SwiftUIEvaluatorError.invalidArguments("Identifier \(identifier) is not defined in this scope.")
    }

    private func assignValue(_ value: SwiftValue, to identifier: String, scope: inout ExpressionScope) throws {
        let resolvedValue = value.resolvingStateReference()
        guard let existing = scope[identifier] else {
            throw SwiftUIEvaluatorError.invalidArguments("Identifier \(identifier) is not defined in this scope.")
        }

        if case .state(let reference) = existing {
            reference.write(resolvedValue)
            return
        }

        scope[identifier] = resolvedValue
    }

    private func isOptional(_ binding: PatternBindingSyntax) -> Bool {
        guard let annotation = binding.typeAnnotation?.type else {
            return false
        }
        return annotation.representsOptional
    }
}

private extension TypeSyntax {
    var representsOptional: Bool {
        if self.is(OptionalTypeSyntax.self) || self.is(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
            return true
        }

        if let attributed = self.as(AttributedTypeSyntax.self) {
            return attributed.baseType.representsOptional
        }

        return false
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

private extension AttributeListSyntax {
    var containsStateAttribute: Bool {
        contains { element in
            guard let attribute = element.as(AttributeSyntax.self) else {
                return false
            }
            return attribute.attributeName.trimmedDescription == "State"
        }
    }
}
