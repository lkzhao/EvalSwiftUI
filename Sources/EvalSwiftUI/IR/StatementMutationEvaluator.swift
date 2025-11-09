import SwiftSyntax

struct StatementMutationEvaluator: MutationEvaluating {
    private let expressionResolver: ExpressionEvaluating
    private let context: (any SwiftUIEvaluatorContext)?
    private let stateRegistry: StateRegistry
    private let modifierDispatcher: ModifierDispatching

    init(expressionResolver: ExpressionEvaluating,
         context: (any SwiftUIEvaluatorContext)?,
         stateRegistry: StateRegistry,
         modifierDispatcher: ModifierDispatching) {
        self.expressionResolver = expressionResolver
        self.context = context
        self.stateRegistry = stateRegistry
        self.modifierDispatcher = modifierDispatcher
    }

    func process(variableDecl: VariableDeclSyntax,
                 scope: inout ExpressionScope,
                 allowStateDeclarations: Bool) throws {
        let hasStateAttribute = variableDecl.attributes.containsStateAttribute
        for binding in variableDecl.bindings {
            guard let namePattern = binding.pattern.as(IdentifierPatternSyntax.self),
                  let initializer = binding.initializer else {
                throw SwiftUIEvaluatorError.unsupportedExpression(variableDecl.description)
            }

            var value = try expressionResolver.resolveExpression(
                ExprSyntax(initializer.value),
                scope: scope,
                context: context
            )

            if !hasStateAttribute {
                value = value.copy()
            }

            if binding.representsOptional && !value.isOptional {
                value = .optional(value)
            }

            if hasStateAttribute {
                guard allowStateDeclarations else {
                    throw SwiftUIEvaluatorError.invalidArguments("@State declarations are only supported at the top level.")
                }
                let stateValue = stateRegistry.registerState(identifier: namePattern.identifier.text, initialValue: value)
                scope.set(stateValue, for: namePattern.identifier.text)
                continue
            }

            scope.set(value, for: namePattern.identifier.text)
        }
    }

    func process(expression: ExprSyntax,
                 scope: inout ExpressionScope) throws -> Bool {
        if let sequence = expression.as(SequenceExprSyntax.self) {
            if try processAssignmentSequence(sequence, scope: &scope) {
                return true
            }

            if try processCompoundAssignmentSequence(sequence, scope: &scope) {
                return true
            }

            return false
        }

        return try processStatefulMemberFunctionCall(expression, scope: scope)
    }

    private func processStatefulMemberFunctionCall(
        _ expression: ExprSyntax,
        scope: ExpressionScope
    ) throws -> Bool {
        guard let callExpr = expression.as(FunctionCallExprSyntax.self),
              let memberAccess = callExpr.calledExpression.as(MemberAccessExprSyntax.self),
              modifierDispatcher.hasHandler(named: memberAccess.declName.baseName.text) else {
            return false
        }

        guard memberAccess.base?.as(FunctionCallExprSyntax.self) == nil else {
            return false
        }

        _ = try expressionResolver.resolveExpression(
            expression,
            scope: scope,
            context: context
        )
        return true
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
        let currentValue = try currentValue(for: identifier.baseName.text, scope: scope)
        currentValue.replace(with: rhsValue)
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
        guard ["+=", "-=", "*=", "/="].contains(symbol) else {
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
        currentValue.replace(with: newValue)
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
            return scoped
        }
        throw SwiftUIEvaluatorError.invalidArguments("Identifier \(identifier) is not defined in this scope.")
    }
}

private extension PatternBindingSyntax {
    var representsOptional: Bool {
        guard let annotation = typeAnnotation?.type else {
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
